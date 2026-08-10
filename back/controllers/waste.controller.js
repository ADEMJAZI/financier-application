const Waste = require('../models/Waste');
const Product = require('../models/Product');
const Business = require('../models/Business');
const mongoose = require('mongoose');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Create waste record
exports.createWaste = async (req, res) => {
  const session = await mongoose.startSession();
  
  try {
    const { business, product, quantity, reason, notes } = req.body;

    // Validate required fields
    if (!business || !product || quantity === undefined || !reason) {
      return res.status(400).json({
        message: 'business, product, quantity and reason are required',
      });
    }

    // Validate ID formats
    if (!mongoose.Types.ObjectId.isValid(business) || !mongoose.Types.ObjectId.isValid(product)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate quantity
    if (quantity <= 0) {
      return res.status(400).json({
        message: 'Quantity must be greater than 0',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Business not found',
      });
    }

    // Start transaction
    session.startTransaction();

    // Fetch the product within transaction
    const productDoc = await Product.findById(product).session(session);
    if (!productDoc) {
      await session.abortTransaction();
      return res.status(404).json({
        message: 'Product not found',
      });
    }

    // Check if enough stock available
    if (productDoc.quantity < quantity) {
      await session.abortTransaction();
      return res.status(400).json({
        message: 'Waste quantity exceeds available stock',
        availableQuantity: productDoc.quantity,
      });
    }

    // Calculate estimated loss
    const estimatedLoss = quantity * productDoc.purchasePrice;

    // Decrement product quantity
    productDoc.quantity -= quantity;
    await productDoc.save({ session });

    // Create waste record
    const waste = new Waste({
      business,
      product,
      quantity,
      reason,
      estimatedLoss,
      notes,
    });

    const savedWaste = await waste.save({ session });

    // Commit transaction
    await session.commitTransaction();

    res.status(201).json({
      success: true,
      message: 'Waste recorded successfully',
      data: savedWaste,
    });
  } catch (error) {
    await session.abortTransaction();
    res.status(500).json({
      message: error.message,
    });
  } finally {
    session.endSession();
  }
};

// Get waste by business ID
exports.getWasteByBusiness = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { from, to, reason } = req.query;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Business not found',
      });
    }

    let query = { business: businessId };

    // Add date range filter if provided
    if (from || to) {
      query.date = {};
      if (from) {
        query.date.$gte = new Date(from);
      }
      if (to) {
        query.date.$lte = new Date(to);
      }
    }

    // Add reason filter if provided
    if (reason && ['expired', 'damaged', 'spillage', 'other'].includes(reason)) {
      query.reason = reason;
    }

    const waste = await Waste.find(query)
      .populate('product', 'name unit')
      .sort({ date: -1 }); // Sort by date descending

    res.status(200).json({
      success: true,
      data: waste,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Get waste total by business ID
exports.getWasteTotalByBusiness = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { from, to } = req.query;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Business not found',
      });
    }

    let matchQuery = { business: new mongoose.Types.ObjectId(businessId) };

    // Add date range filter if provided
    if (from || to) {
      matchQuery.date = {};
      if (from) {
        matchQuery.date.$gte = new Date(from);
      }
      if (to) {
        matchQuery.date.$lte = new Date(to);
      }
    }

    const result = await Waste.aggregate([
      { $match: matchQuery },
      {
        $group: {
          _id: null,
          totalLoss: { $sum: '$estimatedLoss' },
          count: { $sum: 1 },
        },
      },
    ]);

    const totalLoss = result.length > 0 ? result[0].totalLoss : 0;
    const count = result.length > 0 ? result[0].count : 0;

    res.status(200).json({
      success: true,
      data: {
        totalLoss,
        count,
      },
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Delete waste by ID
exports.deleteWaste = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Find first — we need the business field to verify ownership
    // before touching the document (find-then-verify-then-delete).
    const waste = await Waste.findById(id);

    if (!waste) {
      return res.status(404).json({
        message: 'Waste not found',
      });
    }

    // Verify business ownership BEFORE deleting
    const isOwner = await verifyBusinessOwnership(waste.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Waste not found',
      });
    }

    await Waste.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Waste deleted successfully',
      data: waste,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};