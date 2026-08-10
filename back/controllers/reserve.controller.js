const Reserve = require('../models/Reserve');
const Business = require('../models/Business');
const { logAudit } = require('../middleware/auditLogger');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Create a new reserve
exports.createReserve = async (req, res) => {
  try {
    const { business, name } = req.body;

    // Validate required fields
    if (!business || !name) {
      return res.status(400).json({
        success: false,
        message: 'Required fields: business, name',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    const reserve = new Reserve({
      business,
      name,
      balance: 0,
      transactions: [],
    });

    const savedReserve = await reserve.save();

    res.status(201).json({
      success: true,
      message: 'Reserve created successfully',
      data: savedReserve,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get reserves by business ID
exports.getReservesByBusiness = async (req, res) => {
  try {
    const { businessId } = req.params;

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(businessId, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    const reserves = await Reserve.find({ business: businessId }).populate('business');

    res.status(200).json({
      success: true,
      data: reserves,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Deposit to reserve
exports.deposit = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, note } = req.body;

    // Validate amount
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Amount must be greater than 0',
      });
    }

    const reserve = await Reserve.findById(id);

    if (!reserve) {
      return res.status(404).json({
        success: false,
        message: 'Reserve not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(reserve.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Reserve not found',
      });
    }

    // Add amount to balance
    reserve.balance += amount;

    // Add transaction
    reserve.transactions.push({
      type: 'deposit',
      amount,
      note,
      date: new Date(),
    });

    const updatedReserve = await reserve.save();

    res.status(200).json({
      success: true,
      message: 'Deposit successful',
      data: updatedReserve,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Withdraw from reserve
exports.withdraw = async (req, res) => {
  try {
    const { id } = req.params;
    const { amount, note } = req.body;

    // Validate amount
    if (!amount || amount <= 0) {
      return res.status(400).json({
        success: false,
        message: 'Amount must be greater than 0',
      });
    }

    const reserve = await Reserve.findById(id);

    if (!reserve) {
      return res.status(404).json({
        success: false,
        message: 'Reserve not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(reserve.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Reserve not found',
      });
    }

    // Check if balance is sufficient
    if (reserve.balance < amount) {
      return res.status(400).json({
        success: false,
        message: `Insufficient balance. Current balance: ${reserve.balance}, Requested amount: ${amount}`,
      });
    }

    // Store old balance for audit trail
    const oldBalance = reserve.balance;

    // Subtract amount from balance
    reserve.balance -= amount;

    // Add transaction
    reserve.transactions.push({
      type: 'withdrawal',
      amount,
      note,
      date: new Date(),
    });

    const updatedReserve = await reserve.save();

    // Log audit trail
    const performedBy = req.headers['x-user-id'] || 'system';
    const changes = {
      balance: { old: oldBalance, new: reserve.balance },
      withdrawalNote: note || null,
    };
    await logAudit(reserve.business, 'Reserve', reserve._id, 'update', changes, performedBy);

    res.status(200).json({
      success: true,
      message: 'Withdrawal successful',
      data: updatedReserve,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete reserve by ID
exports.deleteReserve = async (req, res) => {
  try {
    const { id } = req.params;

    // Find first — we need the business field to verify ownership
    // before touching the document (find-then-verify-then-delete).
    const reserve = await Reserve.findById(id);

    if (!reserve) {
      return res.status(404).json({
        success: false,
        message: 'Reserve not found',
      });
    }

    // Verify business ownership BEFORE deleting
    const isOwner = await verifyBusinessOwnership(reserve.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Reserve not found',
      });
    }

    await Reserve.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Reserve deleted successfully',
      data: reserve,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};