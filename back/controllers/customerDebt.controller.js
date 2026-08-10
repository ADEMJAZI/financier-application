const CustomerDebt = require('../models/CustomerDebt');
const Business = require('../models/Business');
const mongoose = require('mongoose');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Create a new debt
exports.createDebt = async (req, res) => {
  try {
    const { business, customerName, totalAmount, customerPhone, dueDate, description } = req.body;

    // Validate required fields
    if (!business || !customerName || totalAmount === undefined) {
      return res.status(400).json({
        message: 'business, customerName and totalAmount are required',
      });
    }

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(business)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate amount
    if (totalAmount < 0) {
      return res.status(400).json({
        message: 'Total amount cannot be negative',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Business not found',
      });
    }

    const debt = new CustomerDebt({
      business,
      customerName: customerName.trim(),
      customerPhone: customerPhone?.trim(),
      totalAmount,
      paidAmount: 0,
      status: 'unpaid',
      dueDate,
      description,
      payments: [],
    });

    const savedDebt = await debt.save();

    res.status(201).json({
      success: true,
      message: 'Debt created successfully',
      data: savedDebt,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Get debts by business ID
exports.getDebtsByBusiness = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { status } = req.query;

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
    if (status && ['unpaid', 'partial', 'paid'].includes(status)) {
      query.status = status;
    }

    const debts = await CustomerDebt.find(query)
      .populate('business')
      .sort({ dueDate: 1, _id: 1 }); // dueDate ascending, nulls last naturally in MongoDB

    res.status(200).json({
      success: true,
      data: debts,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Get debt by ID
exports.getDebtById = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    const debt = await CustomerDebt.findById(id).populate('business');

    if (!debt) {
      return res.status(404).json({
        message: 'CustomerDebt not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(debt.business._id || debt.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'CustomerDebt not found',
      });
    }

    res.status(200).json({
      success: true,
      data: debt,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Add payment to debt
exports.addPayment = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, note } = req.body;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate required fields
    if (amount === undefined) {
      return res.status(400).json({
        message: 'amount is required',
      });
    }

    // Validate amount
    if (amount <= 0) {
      return res.status(400).json({
        message: 'Amount must be greater than 0',
      });
    }

    const debt = await CustomerDebt.findById(id);

    if (!debt) {
      return res.status(404).json({
        message: 'CustomerDebt not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(debt.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'CustomerDebt not found',
      });
    }

    // Check if payment exceeds remaining debt
    const remainingAmount = debt.totalAmount - debt.paidAmount;
    if (amount > remainingAmount) {
      return res.status(400).json({
        message: 'Payment exceeds remaining debt',
        remainingAmount,
      });
    }

    // Add payment
    debt.payments.push({
      amount,
      note,
      date: new Date(),
    });

    // Update paid amount
    debt.paidAmount += amount;

    // Recalculate status
    if (debt.paidAmount === 0) {
      debt.status = 'unpaid';
    } else if (debt.paidAmount < debt.totalAmount) {
      debt.status = 'partial';
    } else {
      debt.status = 'paid';
    }

    const updatedDebt = await debt.save();

    res.status(200).json({
      success: true,
      message: 'Payment added successfully',
      data: updatedDebt,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Delete debt by ID
exports.deleteDebt = async (req, res) => {
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
    const debt = await CustomerDebt.findById(id);

    if (!debt) {
      return res.status(404).json({
        message: 'CustomerDebt not found',
      });
    }

    // Verify business ownership BEFORE deleting
    const isOwner = await verifyBusinessOwnership(debt.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'CustomerDebt not found',
      });
    }

    await CustomerDebt.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Debt deleted successfully',
      data: debt,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};