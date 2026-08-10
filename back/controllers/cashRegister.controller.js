const CashRegister = require('../models/CashRegister');
const Business = require('../models/Business');
const mongoose = require('mongoose');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Open register
exports.openRegister = async (req, res) => {
  try {
    const { business, openingBalance } = req.body;

    // Validate required fields
    if (!business || openingBalance === undefined) {
      return res.status(400).json({
        message: 'business and openingBalance are required',
      });
    }

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(business)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate amount
    if (openingBalance < 0) {
      return res.status(400).json({
        message: 'Opening balance cannot be negative',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Business not found',
      });
    }

    // Get today's date at midnight UTC
    const today = new Date();
    today.setUTCHours(0, 0, 0, 0);

    // Check if there's already an open register for this business today
    const existingOpenRegister = await CashRegister.findOne({
      business,
      date: today,
      status: 'open',
    });

    if (existingOpenRegister) {
      return res.status(409).json({
        message: 'A cash register is already open for this business today',
      });
    }

    const register = new CashRegister({
      business,
      date: today,
      openingBalance,
      status: 'open',
    });

    const savedRegister = await register.save();

    res.status(201).json({
      success: true,
      message: 'Cash register opened successfully',
      data: savedRegister,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Get registers by business ID
exports.getRegistersByBusiness = async (req, res) => {
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

    const registers = await CashRegister.find(query)
      .populate('business')
      .sort({ date: -1 }); // Sort by date descending

    res.status(200).json({
      success: true,
      data: registers,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Get register by ID
exports.getRegisterById = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    const register = await CashRegister.findById(id).populate('business');

    if (!register) {
      return res.status(404).json({
        message: 'CashRegister not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(register.business._id || register.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'CashRegister not found',
      });
    }

    res.status(200).json({
      success: true,
      data: register,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Close register
exports.closeRegister = async (req, res) => {
  try {
    const { id } = req.params;
    const { closingBalance, expectedBalance, notes } = req.body;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate required fields
    if (closingBalance === undefined) {
      return res.status(400).json({
        message: 'closingBalance is required',
      });
    }

    const register = await CashRegister.findById(id);

    if (!register) {
      return res.status(404).json({
        message: 'CashRegister not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(register.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'CashRegister not found',
      });
    }

    // Check if already closed
    if (register.status === 'closed') {
      return res.status(400).json({
        message: 'Register is already closed',
      });
    }

    // Update register
    register.closingBalance = closingBalance;
    register.expectedBalance = expectedBalance;
    register.difference = expectedBalance !== undefined ? closingBalance - expectedBalance : null;
    register.status = 'closed';
    register.closedAt = new Date();
    register.notes = notes;

    const updatedRegister = await register.save();

    res.status(200).json({
      success: true,
      message: 'Register closed successfully',
      data: updatedRegister,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Delete register by ID
exports.deleteRegister = async (req, res) => {
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
    const register = await CashRegister.findById(id);

    if (!register) {
      return res.status(404).json({
        message: 'CashRegister not found',
      });
    }

    // Verify business ownership BEFORE deleting
    const isOwner = await verifyBusinessOwnership(register.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'CashRegister not found',
      });
    }

    await CashRegister.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Register deleted successfully',
      data: register,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};