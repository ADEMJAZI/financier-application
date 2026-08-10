const Product = require('../models/Product');
const Business = require('../models/Business');
const mongoose = require('mongoose');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Get reorder suggestions
exports.getReorderSuggestions = async (req, res) => {
  try {
    const { businessId } = req.params;

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

    // Find products that need reordering
    const products = await Product.find({
      business: businessId,
      reorderPoint: { $gt: 0 }, // Only products with reorderPoint set
      $expr: { $lte: ['$quantity', '$reorderPoint'] }, // quantity <= reorderPoint
    });

    // Transform and sort by urgency (most negative difference first)
    const suggestions = products
      .map(product => ({
        productId: product._id,
        name: product.name,
        currentQuantity: product.quantity,
        reorderPoint: product.reorderPoint,
        suggestedReorderQuantity: product.reorderQuantity,
        unit: product.unit,
        urgencyScore: product.quantity - product.reorderPoint,
      }))
      .sort((a, b) => a.urgencyScore - b.urgencyScore); // Most urgent (most negative) first

    res.status(200).json({
      success: true,
      data: suggestions,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Update reorder settings
exports.updateReorderSettings = async (req, res) => {
  try {
    const { productId } = req.params;
    const { reorderPoint, reorderQuantity } = req.body;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(productId)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate amounts if provided
    if (reorderPoint !== undefined && reorderPoint < 0) {
      return res.status(400).json({
        message: 'Reorder point cannot be negative',
      });
    }

    if (reorderQuantity !== undefined && reorderQuantity < 0) {
      return res.status(400).json({
        message: 'Reorder quantity cannot be negative',
      });
    }

    const product = await Product.findById(productId);

    if (!product) {
      return res.status(404).json({
        message: 'Product not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(product.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Product not found',
      });
    }

    // Update fields if provided
    if (reorderPoint !== undefined) product.reorderPoint = reorderPoint;
    if (reorderQuantity !== undefined) product.reorderQuantity = reorderQuantity;

    const updatedProduct = await product.save();

    res.status(200).json({
      success: true,
      message: 'Reorder settings updated successfully',
      data: updatedProduct,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};