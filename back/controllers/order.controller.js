const Order = require('../models/Order');
const MenuItem = require('../models/MenuItem');
const Product = require('../models/Product');
const Expense = require('../models/Expense');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');
const mongoose = require('mongoose');

// ─────────────────────────────────────────────────────────────────────────────
// POST /api/orders
// Create a new order (invoice). Validates stock, decrements raw-material
// quantities, and records a stockConsumption snapshot — all in one transaction.
// ─────────────────────────────────────────────────────────────────────────────
exports.createOrder = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { business, items } = req.body;

    // ── 1. Basic field presence ──────────────────────────────────────────────
    if (!business) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ success: false, message: 'business is required' });
    }

    if (!mongoose.Types.ObjectId.isValid(business)) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ success: false, message: 'Invalid business ID format' });
    }

    // ── 2. Business ownership ────────────────────────────────────────────────
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    // ── 3. Items array validation ────────────────────────────────────────────
    if (!Array.isArray(items) || items.length === 0) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'items must be a non-empty array',
      });
    }

    for (const item of items) {
      if (!item.menuItem || !mongoose.Types.ObjectId.isValid(item.menuItem)) {
        await session.abortTransaction();
        session.endSession();
        return res.status(400).json({
          success: false,
          message: `Invalid or missing menuItem ID: ${item.menuItem}`,
        });
      }
      if (!item.quantity || typeof item.quantity !== 'number' || item.quantity < 1) {
        await session.abortTransaction();
        session.endSession();
        return res.status(400).json({
          success: false,
          message: `quantity must be a number >= 1 for menuItem ${item.menuItem}`,
        });
      }
    }

    // ── 4. Fetch and verify all MenuItems (with populated recipe) ────────────
    const menuItemIds = items.map((i) => i.menuItem);
    const menuItemDocs = await MenuItem.find({
      _id: { $in: menuItemIds },
      business,
    })
      .populate('recipe.rawMaterial', 'name unit quantity')
      .session(session);

    // Verify every requested menuItem exists and belongs to this business
    for (const item of items) {
      const found = menuItemDocs.find((m) => m._id.toString() === item.menuItem.toString());
      if (!found) {
        await session.abortTransaction();
        session.endSession();
        return res.status(404).json({
          success: false,
          message: `MenuItem with ID ${item.menuItem} not found or does not belong to this business`,
        });
      }
    }

    // ── 5. Build consumption map: rawMaterial._id → { product, totalRequired } ─
    // Accumulate across ALL order items so the same raw material used in
    // multiple menu items is summed before any stock check.
    const consumptionMap = new Map(); // key: productId string, value: { product, totalRequired }

    for (const item of items) {
      const menuItemDoc = menuItemDocs.find(
        (m) => m._id.toString() === item.menuItem.toString()
      );

      for (const recipeEntry of menuItemDoc.recipe) {
        const rawMaterial = recipeEntry.rawMaterial; // populated Product doc
        const productId = rawMaterial._id.toString();
        const requiredQty = recipeEntry.quantityRequired * item.quantity;

        if (consumptionMap.has(productId)) {
          consumptionMap.get(productId).totalRequired += requiredQty;
        } else {
          consumptionMap.set(productId, {
            product: rawMaterial,
            productName: rawMaterial.name,
            totalRequired: requiredQty,
          });
        }
      }
    }

    // ── 6. Check stock sufficiency for ALL raw materials ─────────────────────
    // Collect ALL insufficient items before aborting so the user sees
    // the complete picture in one response.
    if (consumptionMap.size > 0) {
      // Re-fetch current quantities inside the transaction for accuracy
      const productIds = Array.from(consumptionMap.keys());
      const currentProducts = await Product.find({
        _id: { $in: productIds },
      }).session(session);

      const insufficientItems = [];

      for (const [productId, entry] of consumptionMap) {
        const currentProduct = currentProducts.find(
          (p) => p._id.toString() === productId
        );
        const available = currentProduct ? currentProduct.quantity : 0;

        if (available < entry.totalRequired) {
          insufficientItems.push({
            productName: entry.productName,
            required: entry.totalRequired,
            available,
          });
        }
      }

      if (insufficientItems.length > 0) {
        await session.abortTransaction();
        session.endSession();
        return res.status(400).json({
          success: false,
          message: 'Insufficient stock',
          insufficientItems,
        });
      }

      // ── 7. Decrement stock for each raw material ─────────────────────────
      for (const [productId, entry] of consumptionMap) {
        await Product.findByIdAndUpdate(
          productId,
          { $inc: { quantity: -entry.totalRequired } },
          { session }
        );
      }
    }

    // ── 8. Determine next invoiceNumber for this business ────────────────────
    const lastOrder = await Order.findOne({ business })
      .sort({ invoiceNumber: -1 })
      .select('invoiceNumber')
      .session(session);

    const invoiceNumber = lastOrder ? lastOrder.invoiceNumber + 1 : 1;

    // ── 9. Build order items array with snapshots ────────────────────────────
    const orderItems = items.map((item) => {
      const menuItemDoc = menuItemDocs.find(
        (m) => m._id.toString() === item.menuItem.toString()
      );
      const subtotal = item.quantity * menuItemDoc.sellingPrice;
      return {
        menuItem: menuItemDoc._id,
        name: menuItemDoc.name,
        quantity: item.quantity,
        unitPrice: menuItemDoc.sellingPrice,
        subtotal,
      };
    });

    const totalAmount = orderItems.reduce((sum, i) => sum + i.subtotal, 0);

    // ── 10. Build stockConsumption snapshot ──────────────────────────────────
    const stockConsumption = Array.from(consumptionMap.values()).map((entry) => ({
      product: entry.product._id,
      productName: entry.productName,
      quantityConsumed: entry.totalRequired,
    }));

    // ── 11. Create and save the order ────────────────────────────────────────
    const [savedOrder] = await Order.create(
      [
        {
          business,
          invoiceNumber,
          items: orderItems,
          totalAmount,
          stockConsumption,
          status: 'completed',
        },
      ],
      { session }
    );

    await session.commitTransaction();
    session.endSession();

    res.status(201).json({
      success: true,
      message: 'Order created successfully',
      data: savedOrder,
    });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();

    // Handle duplicate invoiceNumber (race condition safety net)
    if (error.code === 11000 && error.keyPattern && error.keyPattern.invoiceNumber) {
      return res.status(409).json({
        success: false,
        message: 'Invoice number conflict, please retry the request',
      });
    }

    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/orders/business/:businessId?from=&to=&status=
// List all orders for a business with optional date range and status filters.
// ─────────────────────────────────────────────────────────────────────────────
exports.getOrdersByBusiness = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { from, to, status } = req.query;

    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({ success: false, message: 'Invalid business ID format' });
    }

    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    const filter = { business: businessId };

    if (from || to) {
      filter.date = {};
      if (from) filter.date.$gte = new Date(from);
      if (to) filter.date.$lte = new Date(to);
    }

    if (status) {
      if (!['completed', 'voided'].includes(status)) {
        return res.status(400).json({
          success: false,
          message: 'status must be "completed" or "voided"',
        });
      }
      filter.status = status;
    }

    const orders = await Order.find(filter).sort({ date: -1 });

    res.status(200).json({ success: true, data: orders });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/orders/:id
// Fetch a single order by ID including its stockConsumption snapshot.
// ─────────────────────────────────────────────────────────────────────────────
exports.getOrderById = async (req, res) => {
  try {
    const { id } = req.params;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({ success: false, message: 'Invalid order ID format' });
    }

    const order = await Order.findById(id);

    if (!order) {
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    const isOwner = await verifyBusinessOwnership(order.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    res.status(200).json({ success: true, data: order });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// PATCH /api/orders/:id/void
// Void a completed order: restore stock from the stored snapshot (not the
// current recipe), mark as voided. All stock changes run in a transaction.
// ─────────────────────────────────────────────────────────────────────────────
exports.voidOrder = async (req, res) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { id } = req.params;
    const { reason } = req.body;

    if (!mongoose.Types.ObjectId.isValid(id)) {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({ success: false, message: 'Invalid order ID format' });
    }

    const order = await Order.findById(id).session(session);

    if (!order) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({ success: false, message: 'Order not found' });
    }

    const isOwner = await verifyBusinessOwnership(order.business, req.user._id);
    if (!isOwner) {
      await session.abortTransaction();
      session.endSession();
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    if (order.status === 'voided') {
      await session.abortTransaction();
      session.endSession();
      return res.status(400).json({
        success: false,
        message: 'Order is already voided',
      });
    }

    // Restore raw-material stock using the stored snapshot
    for (const consumed of order.stockConsumption) {
      await Product.findByIdAndUpdate(
        consumed.product,
        { $inc: { quantity: consumed.quantityConsumed } },
        { session }
      );
    }

    // Mark as voided
    order.status = 'voided';
    order.voidedAt = new Date();
    order.voidReason = reason || null;

    await order.save({ session });

    await session.commitTransaction();
    session.endSession();

    res.status(200).json({
      success: true,
      message: 'Order voided successfully',
      data: order,
    });
  } catch (error) {
    await session.abortTransaction();
    session.endSession();
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/orders/business/:businessId/daily-summary?date=
// Aggregation: revenue, order count, per-menu-item breakdown, and stock
// consumed (from stockConsumption snapshots) for a given day.
// ─────────────────────────────────────────────────────────────────────────────
exports.getDailySummary = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { date } = req.query;

    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({ success: false, message: 'Invalid business ID format' });
    }

    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    const targetDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(targetDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(targetDate);
    endOfDay.setHours(23, 59, 59, 999);

    const businessObjectId = new mongoose.Types.ObjectId(businessId);

    // ── Revenue & order count ────────────────────────────────────────────────
    const revenueAgg = await Order.aggregate([
      {
        $match: {
          business: businessObjectId,
          status: 'completed',
          date: { $gte: startOfDay, $lte: endOfDay },
        },
      },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$totalAmount' },
          orderCount: { $sum: 1 },
        },
      },
    ]);

    const totalRevenue = revenueAgg.length > 0 ? revenueAgg[0].totalRevenue : 0;
    const orderCount = revenueAgg.length > 0 ? revenueAgg[0].orderCount : 0;

    // ── Per-menu-item breakdown ──────────────────────────────────────────────
    const byMenuItemAgg = await Order.aggregate([
      {
        $match: {
          business: businessObjectId,
          status: 'completed',
          date: { $gte: startOfDay, $lte: endOfDay },
        },
      },
      { $unwind: '$items' },
      {
        $group: {
          _id: '$items.name',
          quantitySold: { $sum: '$items.quantity' },
          revenue: { $sum: '$items.subtotal' },
        },
      },
      { $sort: { revenue: -1 } },
    ]);

    const byMenuItem = byMenuItemAgg.map((item) => ({
      name: item._id,
      quantitySold: item.quantitySold,
      revenue: item.revenue,
    }));

    // ── Stock consumed (from stockConsumption snapshots) ─────────────────────
    const stockConsumedAgg = await Order.aggregate([
      {
        $match: {
          business: businessObjectId,
          status: 'completed',
          date: { $gte: startOfDay, $lte: endOfDay },
        },
      },
      { $unwind: '$stockConsumption' },
      {
        $group: {
          _id: {
            product: '$stockConsumption.product',
            productName: '$stockConsumption.productName',
          },
          totalQuantityConsumed: { $sum: '$stockConsumption.quantityConsumed' },
        },
      },
      // Optionally join Product for the unit field
      {
        $lookup: {
          from: 'products',
          localField: '_id.product',
          foreignField: '_id',
          as: 'productDetails',
        },
      },
      {
        $unwind: {
          path: '$productDetails',
          preserveNullAndEmptyArrays: true,
        },
      },
      { $sort: { totalQuantityConsumed: -1 } },
    ]);

    const stockConsumed = stockConsumedAgg.map((entry) => ({
      productName: entry._id.productName,
      totalQuantityConsumed: entry.totalQuantityConsumed,
      unit: entry.productDetails ? entry.productDetails.unit : null,
    }));

    res.status(200).json({
      success: true,
      data: {
        date: startOfDay,
        totalRevenue,
        orderCount,
        byMenuItem,
        stockConsumed,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};

// ─────────────────────────────────────────────────────────────────────────────
// GET /api/orders/business/:businessId/daily-profit?date=
// Combines order revenue with that day's Expense sum → net profit.
// ─────────────────────────────────────────────────────────────────────────────
exports.getDailyProfitReport = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { date } = req.query;

    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({ success: false, message: 'Invalid business ID format' });
    }

    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    const targetDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(targetDate);
    startOfDay.setHours(0, 0, 0, 0);
    const endOfDay = new Date(targetDate);
    endOfDay.setHours(23, 59, 59, 999);

    const businessObjectId = new mongoose.Types.ObjectId(businessId);

    // Revenue from completed orders on this day
    const revenueResult = await Order.aggregate([
      {
        $match: {
          business: businessObjectId,
          status: 'completed',
          date: { $gte: startOfDay, $lte: endOfDay },
        },
      },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: '$totalAmount' },
        },
      },
    ]);

    const totalRevenue = revenueResult.length > 0 ? revenueResult[0].totalRevenue : 0;

    // Expenses on this day (same pattern as existing endpoints)
    const expenseResult = await Expense.aggregate([
      {
        $match: {
          business: businessObjectId,
          date: { $gte: startOfDay, $lte: endOfDay },
        },
      },
      {
        $group: {
          _id: null,
          totalExpenses: { $sum: '$amount' },
        },
      },
    ]);

    const totalExpenses = expenseResult.length > 0 ? expenseResult[0].totalExpenses : 0;
    const netProfit = totalRevenue - totalExpenses;

    res.status(200).json({
      success: true,
      data: {
        date: startOfDay,
        totalRevenue,
        totalExpenses,
        netProfit,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, message: error.message });
  }
};
