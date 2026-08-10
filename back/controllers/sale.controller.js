const Sale = require('../models/Sale');
const Product = require('../models/Product');
const Expense = require('../models/Expense');
const mongoose = require('mongoose');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Record a sale (with stock deduction)
exports.recordSale = async (req, res, next) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { business, product, quantity = 1 } = req.body;

    // Validate required fields
    if (!business || !product) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: 'Required fields: business, product',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      await session.abortTransaction();
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    // Fetch product and check stock
    const productDoc = await Product.findById(product).session(session);
    
    if (!productDoc) {
      await session.abortTransaction();
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    // Check if enough stock available
    if (productDoc.quantity < quantity) {
      await session.abortTransaction();
      return res.status(400).json({
        success: false,
        message: `Insufficient stock. Available: ${productDoc.quantity} ${productDoc.unit}`,
        availableQuantity: productDoc.quantity,
      });
    }

    // Deduct stock
    productDoc.quantity -= quantity;
    await productDoc.save({ session });

    // Create sale with snapshot price
    const sale = new Sale({
      business,
      product,
      quantity,
      unitPrice: productDoc.price, // Snapshot current price
      totalAmount: quantity * productDoc.price,
      date: new Date(),
    });

    await sale.save({ session });

    // Commit transaction
    await session.commitTransaction();

    // Populate product info for response
    await sale.populate('product', 'name unit');

    res.status(201).json({
      success: true,
      message: 'Sale recorded successfully',
      data: sale,
    });
  } catch (error) {
    await session.abortTransaction();
    res.status(500).json({
      success: false,
      message: error.message,
    });
  } finally {
    session.endSession();
  }
};

// Get sales by business
exports.getSalesByBusiness = async (req, res, next) => {
  try {
    const { businessId } = req.params;
    const { from, to } = req.query;

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    let query = { business: businessId };

    // Date range filter
    if (from || to) {
      query.date = {};
      if (from) query.date.$gte = new Date(from);
      if (to) query.date.$lte = new Date(to);
    }

    const sales = await Sale.find(query)
      .populate('product', 'name unit')
      .sort({ date: -1 });

    res.status(200).json({
      success: true,
      data: sales,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get daily summary
exports.getDailySummary = async (req, res, next) => {
  try {
    const { businessId } = req.params;
    const { date } = req.query;

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    // Default to today if no date provided
    const targetDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
    const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

    const summary = await Sale.aggregate([
      {
        $match: {
          business: new mongoose.Types.ObjectId(businessId),
          date: {
            $gte: startOfDay,
            $lte: endOfDay,
          },
        },
      },
      {
        $lookup: {
          from: 'products',
          localField: 'product',
          foreignField: '_id',
          as: 'productInfo',
        },
      },
      {
        $unwind: '$productInfo',
      },
      {
        $group: {
          _id: '$product',
          productName: { $first: '$productInfo.name' },
          quantitySold: { $sum: '$quantity' },
          revenue: { $sum: '$totalAmount' },
        },
      },
      {
        $project: {
          _id: 0,
          productName: 1,
          quantitySold: 1,
          revenue: 1,
        },
      },
    ]);

    // Calculate totals
    const totalRevenue = summary.reduce((sum, item) => sum + item.revenue, 0);
    const saleCount = await Sale.countDocuments({
      business: businessId,
      date: { $gte: startOfDay, $lte: endOfDay },
    });

    res.status(200).json({
      success: true,
      data: {
        date: startOfDay,
        totalRevenue,
        saleCount,
        byProduct: summary,
      },
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get daily profit report (revenue - expenses)
exports.getDailyProfitReport = async (req, res, next) => {
  try {
    const { businessId } = req.params;
    const { date } = req.query;

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    // Default to today if no date provided
    const targetDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
    const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

    // Get total revenue
    const revenueResult = await Sale.aggregate([
      {
        $match: {
          business: new mongoose.Types.ObjectId(businessId),
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

    const totalRevenue = revenueResult[0]?.totalRevenue || 0;

    // Get total expenses
    const expenseResult = await Expense.aggregate([
      {
        $match: {
          business: new mongoose.Types.ObjectId(businessId),
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

    const totalExpenses = expenseResult[0]?.totalExpenses || 0;

    // Calculate net profit
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
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete sale (undo) - restores stock
exports.deleteSale = async (req, res, next) => {
  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { id } = req.params;

    const sale = await Sale.findById(id).session(session);

    if (!sale) {
      await session.abortTransaction();
      return res.status(404).json({
        success: false,
        message: 'Sale not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(sale.business, req.user._id);
    if (!isOwner) {
      await session.abortTransaction();
      return res.status(404).json({
        success: false,
        message: 'Sale not found',
      });
    }

    // Restore product quantity
    const product = await Product.findById(sale.product).session(session);
    
    if (product) {
      product.quantity += sale.quantity;
      await product.save({ session });
    }

    // Delete sale
    await Sale.findByIdAndDelete(id).session(session);

    // Commit transaction
    await session.commitTransaction();

    res.status(200).json({
      success: true,
      message: 'Sale deleted and stock restored successfully',
      data: sale,
    });
  } catch (error) {
    await session.abortTransaction();
    res.status(500).json({
      success: false,
      message: error.message,
    });
  } finally {
    session.endSession();
  }
};
