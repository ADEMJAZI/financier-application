const Product = require('../models/Product');
const Business = require('../models/Business');
const { logAudit } = require('../middleware/auditLogger');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Create a new product
exports.createProduct = async (req, res) => {
  try {
    const { business, name, purchasePrice, price, quantity, unit } = req.body;

    // Validate required fields
    if (!business || !name || purchasePrice === undefined || price === undefined || quantity === undefined || !unit) {
      return res.status(400).json({
        success: false,
        message: 'Required fields: business, name, purchasePrice, price, quantity, unit',
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

    // Check for duplicate product (case-insensitive, trimmed)
    const existingProduct = await Product.findOne({
      business,
      name: { $regex: new RegExp(`^${name.trim()}$`, 'i') }
    });

    if (existingProduct) {
      return res.status(409).json({
        message: 'This product already exists in stock. Please update the quantity instead of adding a new product.',
        existingProduct,
      });
    }

    const product = new Product({
      business,
      name: name.trim(),
      purchasePrice,
      price,
      quantity,
      unit,
    });

    const savedProduct = await product.save();

    res.status(201).json({
      success: true,
      message: 'Product created successfully',
      data: savedProduct,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get products by business ID
exports.getProductsByBusiness = async (req, res) => {
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

    const products = await Product.find({ business: businessId });

    res.status(200).json({
      success: true,
      data: products,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get product by ID
exports.getProductById = async (req, res) => {
  try {
    const { id } = req.params;

    const product = await Product.findById(id).populate('business');

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(product.business._id || product.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    res.status(200).json({
      success: true,
      data: product,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Update product by ID
exports.updateProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { business, name, purchasePrice, price, quantity, unit } = req.body;

    const product = await Product.findById(id);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(product.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    // Store old values for audit trail
    const oldProduct = product.toObject();
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
      if (product.business.toString() !== business) {
        changes.business = { old: product.business, new: business };
      }
      product.business = business;
    }

    // Update fields if provided and track changes
    if (name !== undefined && product.name !== name) {
      changes.name = { old: product.name, new: name };
      product.name = name;
    }
    if (purchasePrice !== undefined && product.purchasePrice !== purchasePrice) {
      changes.purchasePrice = { old: product.purchasePrice, new: purchasePrice };
      product.purchasePrice = purchasePrice;
    }
    if (price !== undefined && product.price !== price) {
      changes.price = { old: product.price, new: price };
      product.price = price;
    }
    if (quantity !== undefined && product.quantity !== quantity) {
      changes.quantity = { old: product.quantity, new: quantity };
      product.quantity = quantity;
    }
    if (unit !== undefined && product.unit !== unit) {
      changes.unit = { old: product.unit, new: unit };
      product.unit = unit;
    }

    const updatedProduct = await product.save();

    // Log audit trail if there were changes
    if (Object.keys(changes).length > 0) {
      const performedBy = req.headers['x-user-id'] || 'system';
      await logAudit(product.business, 'Product', product._id, 'update', changes, performedBy);
    }

    res.status(200).json({
      success: true,
      message: 'Product updated successfully',
      data: updatedProduct,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete product by ID
exports.deleteProduct = async (req, res) => {
  try {
    const { id } = req.params;

    const product = await Product.findById(id);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(product.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    // Store full document for audit trail
    const deletedProduct = product.toObject();
    
    await Product.findByIdAndDelete(id);

    // Log audit trail
    const performedBy = req.headers['x-user-id'] || 'system';
    await logAudit(product.business, 'Product', product._id, 'delete', deletedProduct, performedBy);

    res.status(200).json({
      success: true,
      message: 'Product deleted successfully',
      data: deletedProduct,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Restock product
exports.restockProduct = async (req, res) => {
  try {
    const { id } = req.params;
    const { quantityToAdd, newPurchasePrice } = req.body;

    // Validate quantityToAdd
    if (quantityToAdd === undefined || quantityToAdd <= 0) {
      return res.status(400).json({
        success: false,
        message: 'quantityToAdd is required and must be greater than 0',
      });
    }

    const product = await Product.findById(id);

    if (!product) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(product.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        success: false,
        message: 'Product not found',
      });
    }

    // Increment quantity
    product.quantity += quantityToAdd;

    // Update purchase price if provided
    if (newPurchasePrice !== undefined) {
      product.purchasePrice = newPurchasePrice;
    }

    const updatedProduct = await product.save();

    res.status(200).json({
      success: true,
      message: 'Product restocked successfully',
      data: updatedProduct,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
