const MenuItemSale = require('../models/MenuItemSale');
const MenuItem = require('../models/MenuItem');
const Expense = require('../models/Expense');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');
const mongoose = require('mongoose');

// Record a menu item sale
exports.recordSale = async (req, res) => {
  try {
    const { business, menuItem, quantity = 1 } = req.body;

    // Validate required fields
    if (!business || !menuItem) {
      return res.status(400).json({
        success: false,
        message: 'Required fields: business, menuItem',
      });
    }

    // Validate ObjectId formats
    if (!mongoose.Types.ObjectId.isValid(business) || !mongoose.Types.ObjectId.isValid(menuItem)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid business or menuItem ID format',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    // Fetch the MenuItem to get current selling price
    const menuItemDoc = await MenuItem.findById(menuItem);

    if (!menuItemDoc) {
      return res.status(404).json({
        success: false,
        message: 'Menu item not found',
      });
    }

    // Verify the menu item belongs to the same business
    if (menuItemDoc.business.toString() !== business.toString()) {
      return res.status(400).json({
        success: false,
        message: 'Menu item does not belong to this business',
      });
    }

    // Snapshot the selling price as unitPrice
    const unitPrice = menuItemDoc.sellingPrice;

    // Calculate total amount
    const totalAmount = quantity * unitPrice;

    // Create the sale
    const sale = new MenuItemSale({
      business,
      menuItem,
      quantity,
      unitPrice,
      totalAmount,
    });

    const savedSale = await sale.save();

    // Populate menuItem details for response
    const populatedSale = await MenuItemSale.findById(savedSale._id).populate('menuItem');

    res.status(201).json({
      success: true,
      message: 'Sale recorded successfully',
      data: populatedSale,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get sales by business ID
exports.getSalesByBusiness = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { from, to } = req.query;

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid business ID format',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    // Build query filter
    const filter = { business: businessId };

    // Add date range filter if provided
    if (from || to) {
      filter.date = {};
      if (from) {
        filter.date.$gte = new Date(from);
      }
      if (to) {
        filter.date.$lte = new Date(to);
      }
    }

    const sales = await MenuItemSale.find(filter)
      .populate('menuItem')
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

// Get daily summary for a specific date
exports.getDailySummary = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { date } = req.query;

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid business ID format',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    // Determine the target date (default to today)
    const targetDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
    const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

    // Aggregation pipeline
    const summary = await MenuItemSale.aggregate([
      {
        $match: {
          business: new mongoose.Types.ObjectId(businessId),
          date: { $gte: startOfDay, $lte: endOfDay },
        },
      },
      {
        $lookup: {
          from: 'menuitems',
          localField: 'menuItem',
          foreignField: '_id',
          as: 'menuItemDetails',
        },
      },
      {
        $unwind: '$menuItemDetails',
      },
      {
        $group: {
          _id: '$menuItem',
          name: { $first: '$menuItemDetails.name' },
          quantitySold: { $sum: '$quantity' },
          revenue: { $sum: '$totalAmount' },
        },
      },
      {
        $sort: { revenue: -1 },
      },
    ]);

    // Calculate totals
    const totalRevenue = summary.reduce((sum, item) => sum + item.revenue, 0);
    const saleCount = summary.reduce((sum, item) => sum + item.quantitySold, 0);

    res.status(200).json({
      success: true,
      data: {
        date: startOfDay,
        totalRevenue,
        saleCount,
        byMenuItem: summary.map((item) => ({
          name: item.name,
          quantitySold: item.quantitySold,
          revenue: item.revenue,
        })),
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
exports.getDailyProfitReport = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { date } = req.query;

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid business ID format',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    // Determine the target date (default to today)
    const targetDate = date ? new Date(date) : new Date();
    const startOfDay = new Date(targetDate.setHours(0, 0, 0, 0));
    const endOfDay = new Date(targetDate.setHours(23, 59, 59, 999));

    // Calculate total revenue from menu item sales
    const revenueResult = await MenuItemSale.aggregate([
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

    const totalRevenue = revenueResult.length > 0 ? revenueResult[0].totalRevenue : 0;

    // Calculate total expenses for the same day
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

    const totalExpenses = expenseResult.length > 0 ? expenseResult[0].totalExpenses : 0;

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

// Delete a sale (undo)
exports.deleteSale = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ObjectId format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid sale ID format',
      });
    }

    const sale = await MenuItemSale.findById(id);

    if (!sale) {
      return res.status(404).json({
        success: false,
        message: 'Sale not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(sale.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found or you do not have access',
      });
    }

    // Store full document for response
    const deletedSale = sale.toObject();

    await MenuItemSale.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Sale deleted successfully',
      data: deletedSale,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
