const mongoose = require('mongoose');

const expenseSchema = new mongoose.Schema(
  {
    business: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Business',
      index: true,
      required: [true, 'Business ID is required'],
    },
    category: {
      type: String,
      required: [true, 'Category is required'],
      enum: {
        values: [
          'rent', 'water', 'electricity', 'maintenance',
          'equipment purchase', 'other',
          // AI-generated categories
          'supplies', 'transport', 'food', 'staff', 'utilities',
        ],
        message: 'Invalid category',
      },
    },
    amount: {
      type: Number,
      required: [true, 'Amount is required'],
      min: [0, 'Amount cannot be negative'],
    },
    isFixed: {
      type: Boolean,
      default: false,
    },
    description: {
      type: String,
    },
    date: {
      type: Date,
      default: Date.now,
    },
    // AI-parsing metadata (optional)
    aiParsed: { type: Boolean, default: false },
    originalText: { type: String, default: null },
    aiConfidence: { type: Number, default: null },
  },
  { timestamps: true }
);

module.exports = mongoose.model('Expense', expenseSchema);