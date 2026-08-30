const mongoose = require('mongoose');

const paymentSchema = new mongoose.Schema({
  amount: {
    type: Number,
    required: [true, 'Payment amount is required'],
    min: [0.01, 'Payment amount must be greater than 0'],
  },
  date: {
    type: Date,
    default: Date.now,
  },
  periodLabel: {
    type: String,
  },
  note: {
    type: String,
  },
});

const employeeSchema = new mongoose.Schema(
  {
    business: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Business',
      index: true,
      required: [true, 'Business ID is required'],
    },
    name: {
      type: String,
      required: [true, 'Employee name is required'],
      trim: true,
    },
    role: {
      type: String,
    },
    phone: {
      type: String,
    },
    salary: {
      type: Number,
      required: [true, 'Salary is required'],
      min: [0, 'Salary cannot be negative'],
    },
    salaryType: {
      type: String,
      enum: ['monthly', 'daily', 'hourly'],
      default: 'monthly',
    },
    startDate: {
      type: Date,
      default: Date.now,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    payments: [paymentSchema],
  },
  { timestamps: true }
);

module.exports = mongoose.model('Employee', employeeSchema);