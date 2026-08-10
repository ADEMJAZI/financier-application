const Expense = require('../models/Expense');
const Business = require('../models/Business');
const { logAudit } = require('../middleware/auditLogger');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');
const aiService = require('../services/aiService');

// Create expense from natural language (AI-powered)
exports.createExpenseFromText = async (req, res) => {
  try {
    const { business, text, language = 'ar' } = req.body;

    // Validate required fields
    if (!business || !text) {
      return res.status(400).json({
        message: 'Business ID and text are required'
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Business not found'
      });
    }

    // Parse expense using AI
    const parsedExpense = await aiService.parseExpense(text);

    // Create the expense with parsed data
    const expense = new Expense({
      business,
      category: parsedExpense.category,
      amount: parsedExpense.amount,
      isFixed: false, // AI-parsed expenses are typically variable
      description: parsedExpense.description,
      date: new Date(), // Use current date
      aiParsed: true, // Flag to indicate AI processing
      originalText: text, // Store original text for reference
      aiConfidence: parsedExpense.confidence
    });

    const savedExpense = await expense.save();
    await savedExpense.populate('business', 'name type');

    // Log audit
    await logAudit(req.user._id, business, 'expense', 'create', {
      expenseId: savedExpense._id,
      amount: savedExpense.amount,
      category: savedExpense.category,
      aiParsed: true,
      originalText: text
    });

    res.status(201).json({
      success: true,
      message: 'Expense created from text successfully',
      data: savedExpense,
      aiData: {
        confidence: parsedExpense.confidence,
        originalText: text
      }
    });
  } catch (error) {
    console.error('Create expense from text error:', error);
    res.status(500).json({
      success: false,
      message: error.message.includes('Could not parse') ? error.message : 'Failed to create expense from text'
    });
  }
};

// Create a new expense
exports.createExpense = async (req, res) => {
  try {
    const { business, category, amount, isFixed, description, date } = req.body;

    // Validate required fields
    if (!business || !category || amount === undefined) {
      return res.status(400).json({
        success: false,
        message: 'Required fields: business, category, amount',
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

    const expense = new Expense({
      business,
      category,
      amount,
      isFixed,
      description,
      date: date || Date.now(),
    });

    const savedExpense = await expense.save();

    res.status(201).json({
      success: true,
      message: 'Expense created successfully',
      data: savedExpense,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get expenses by business ID
exports.getExpensesByBusiness = async (req, res) => {
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

    const expenses = await Expense.find({ business: businessId })
      .populate('business')
      .sort({ date: -1 }); // Sort by date descending

    res.status(200).json({
      success: true,
      data: expenses,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Update expense by ID
exports.updateExpense = async (req, res) => {
  try {
    const { id } = req.params;
    const { business, category, amount, isFixed, description, date } = req.body;

    const expense = await Expense.findById(id);

    if (!expense) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(expense.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found',
      });
    }

    // Store old values for audit trail
    const changes = {};

    // If business is being updated, verify it exists and is owned
    if (business !== undefined) {
      const isNewBusinessOwner = await verifyBusinessOwnership(business, req.user._id);
      if (!isNewBusinessOwner) {
        return res.status(404).json({
          success: false,
          message: 'Business not found',
        });
      }
      if (expense.business.toString() !== business) {
        changes.business = { old: expense.business, new: business };
      }
      expense.business = business;
    }

    // Update fields if provided and track changes
    if (category !== undefined && expense.category !== category) {
      changes.category = { old: expense.category, new: category };
      expense.category = category;
    }
    if (amount !== undefined && expense.amount !== amount) {
      changes.amount = { old: expense.amount, new: amount };
      expense.amount = amount;
    }
    if (isFixed !== undefined && expense.isFixed !== isFixed) {
      changes.isFixed = { old: expense.isFixed, new: isFixed };
      expense.isFixed = isFixed;
    }
    if (description !== undefined && expense.description !== description) {
      changes.description = { old: expense.description, new: description };
      expense.description = description;
    }
    if (date !== undefined && expense.date.getTime() !== new Date(date).getTime()) {
      changes.date = { old: expense.date, new: date };
      expense.date = date;
    }

    const updatedExpense = await expense.save();

    // Log audit trail if there were changes
    if (Object.keys(changes).length > 0) {
      const performedBy = req.headers['x-user-id'] || 'system';
      await logAudit(expense.business, 'Expense', expense._id, 'update', changes, performedBy);
    }

    res.status(200).json({
      success: true,
      message: 'Expense updated successfully',
      data: updatedExpense,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete expense by ID
exports.deleteExpense = async (req, res) => {
  try {
    const { id } = req.params;

    const expense = await Expense.findById(id);

    if (!expense) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(expense.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Expense not found',
      });
    }

    // Store full document for audit trail
    const deletedExpense = expense.toObject();
    
    await Expense.findByIdAndDelete(id);

    // Log audit trail
    const performedBy = req.headers['x-user-id'] || 'system';
    await logAudit(expense.business, 'Expense', expense._id, 'delete', deletedExpense, performedBy);

    res.status(200).json({
      success: true,
      message: 'Expense deleted successfully',
      data: deletedExpense,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};