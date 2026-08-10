const mongoose = require('mongoose');

const cashRegisterSchema = new mongoose.Schema(
  {
    business: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Business',
      required: [true, 'Business ID is required'],
    },
    date: {
      type: Date,
      required: [true, 'Date is required'],
    },
    openingBalance: {
      type: Number,
      required: [true, 'Opening balance is required'],
      min: [0, 'Opening balance cannot be negative'],
    },
    closingBalance: {
      type: Number,
      default: null,
    },
    expectedBalance: {
      type: Number,
      default: null,
    },
    difference: {
      type: Number,
      default: null,
    },
    status: {
      type: String,
      enum: ['open', 'closed'],
      default: 'open',
    },
    notes: {
      type: String,
    },
    closedAt: {
      type: Date,
      default: null,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('CashRegister', cashRegisterSchema);