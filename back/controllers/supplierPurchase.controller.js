const SupplierPurchase = require('../models/SupplierPurchase');
const Supplier = require('../models/Supplier');
const Product = require('../models/Product');
const Business = require('../models/Business');
const mongoose = require('mongoose');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Record a purchase
exports.recordPurchase = async (req, res) => {
  const session = await mongoose.startSession();

  try {
    let { business, supplier, product, quantity, unitPrice } = req.body;

    // If supplier comes from URL params, use that instead
    if (req.params.id) {
      supplier = req.params.id;
    }

    // Validate required fields
    if (!business || !supplier || !product || quantity === undefined || unitPrice === undefined) {
      return res.status(400).json({
        message: 'business, supplier, product, quantity and unitPrice are required',
      });
    }

    // Validate ID formats
    if (!mongoose.Types.ObjectId.isValid(business) || 
        !mongoose.Types.ObjectId.isValid(supplier) || 
        !mongoose.Types.ObjectId.isValid(product)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate amounts
    if (quantity <= 0 || unitPrice < 0) {
      return res.status(400).json({
        message: 'Quantity must be greater than 0 and unitPrice cannot be negative',
      });
    }

    // Start transaction
    session.startTransaction();

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      await session.abortTransaction();
      return res.status(404).json({
        message: 'Business not found',
      });
    }

    // Check if supplier exists
    const supplierExists = await Supplier.findById(supplier).session(session);
    if (!supplierExists) {
      await session.abortTransaction();
      return res.status(404).json({
        message: 'Supplier not found',
      });
    }

    // Check if product exists
    const productDoc = await Product.findById(product).session(session);
    if (!productDoc) {
      await session.abortTransaction();
      return res.status(404).json({
        message: 'Product not found',
      });
    }

    // Calculate total cost
    const totalCost = quantity * unitPrice;

    // Create purchase record
    const purchase = new SupplierPurchase({
      business,
      supplier,
      product,
      quantity,
      unitPrice,
      totalCost,
    });

    const savedPurchase = await purchase.save({ session });

    // Update product stock (restock logic)
    productDoc.quantity += quantity;
    productDoc.purchasePrice = unitPrice;
    await productDoc.save({ session });

    // Commit transaction
    await session.commitTransaction();

    res.status(201).json({
      success: true,
      message: 'Purchase recorded successfully',
      data: savedPurchase,
    });
  } catch (error) {
    await session.abortTransaction();
    res.status(500).json({
      message: error.message,
    });
  } finally {
    session.endSession();
  }
};

// Get purchases by supplier ID
exports.getPurchasesBySupplier = async (req, res) => {
  try {
    const { supplierId } = req.params;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(supplierId)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Check if supplier exists
    const supplierExists = await Supplier.findById(supplierId);
    if (!supplierExists) {
      return res.status(404).json({
        message: 'Supplier not found',
      });
    }

    const purchases = await SupplierPurchase.find({ supplier: supplierId })
      .populate('business')
      .populate('supplier')
      .populate('product')
      .sort({ date: -1 }); // Sort by date descending

    res.status(200).json({
      success: true,
      data: purchases,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Get purchases by business ID
exports.getPurchasesByBusiness = async (req, res) => {
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

    const purchases = await SupplierPurchase.find({ business: businessId })
      .populate('business')
      .populate('supplier')
      .populate('product')
      .sort({ date: -1 }); // Sort by date descending

    res.status(200).json({
      success: true,
      data: purchases,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};