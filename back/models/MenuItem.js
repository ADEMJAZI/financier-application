const mongoose = require('mongoose');

const recipeEntrySchema = new mongoose.Schema(
  {
    rawMaterial: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Product',
      required: [true, 'Raw material (Product) reference is required'],
    },
    quantityRequired: {
      type: Number,
      required: [true, 'Quantity required is required'],
      min: [0.001, 'Quantity required must be greater than 0'],
    },
  },
  { _id: true }
);

const menuItemSchema = new mongoose.Schema(
  {
    business: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Business',
      required: [true, 'Business ID is required'],
    },
    name: {
      type: String,
      required: [true, 'Menu item name is required'],
      trim: true,
    },
    sellingPrice: {
      type: Number,
      required: [true, 'Selling price is required'],
      min: [0, 'Selling price cannot be negative'],
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    recipe: {
      type: [recipeEntrySchema],
      default: [],
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('MenuItem', menuItemSchema);
