const mongoose = require('mongoose');

// Subdocument: a single line item in the order
const orderItemSchema = new mongoose.Schema(
  {
    menuItem: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'MenuItem',
      required: [true, 'MenuItem reference is required'],
    },
    name: {
      type: String,
      required: [true, 'Item name snapshot is required'],
    },
    quantity: {
      type: Number,
      required: [true, 'Quantity is required'],
      min: [1, 'Quantity must be at least 1'],
    },
    unitPrice: {
      type: Number,
      required: [true, 'Unit price snapshot is required'],
    },
    subtotal: {
      type: Number,
      required: true,
    },
  },
  { _id: true }
);

// Subdocument: snapshot of raw-material consumption for this order
// Used to accurately restore stock if the order is voided,
// independent of any future recipe changes.
const stockConsumptionSchema = new mongoose.Schema(
  {
    product: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: [true, 'Product reference is required'],
    },
    productName: {
      type: String,
      required: [true, 'Product name snapshot is required'],
    },
    quantityConsumed: {
      type: Number,
      required: [true, 'Quantity consumed is required'],
    },
  },
  { _id: true }
);

const orderSchema = new mongoose.Schema(
  {
    business: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Business',
      required: [true, 'Business ID is required'],
    },
    // Sequential invoice number per business (1, 2, 3, …).
    // Enforced as unique per business via compound index below.
    invoiceNumber: {
      type: Number,
      required: [true, 'Invoice number is required'],
    },
    items: {
      type: [orderItemSchema],
      validate: {
        validator: (arr) => Array.isArray(arr) && arr.length > 0,
        message: 'An order must contain at least one item',
      },
    },
    totalAmount: {
      type: Number,
      required: true,
    },
    // Snapshot of exactly how much of each raw material was deducted.
    stockConsumption: {
      type: [stockConsumptionSchema],
      default: [],
    },
    status: {
      type: String,
      enum: ['completed', 'voided'],
      default: 'completed',
    },
    voidedAt: {
      type: Date,
      default: null,
    },
    voidReason: {
      type: String,
      default: null,
    },
    date: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Compound unique index: safety net to prevent duplicate invoice numbers
// per business even under concurrent requests.
orderSchema.index({ business: 1, invoiceNumber: 1 }, { unique: true });

module.exports = mongoose.model('Order', orderSchema);
