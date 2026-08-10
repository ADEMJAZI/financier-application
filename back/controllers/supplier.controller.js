const Supplier = require('../models/Supplier');
const Business = require('../models/Business');
const mongoose = require('mongoose');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Create a new supplier
exports.createSupplier = async (req, res) => {
  try {
    const { business, name, phone, address, notes } = req.body;

    // Validate required fields
    if (!business || !name) {
      return res.status(400).json({
        message: 'business and name are required',
      });
    }

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(business)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Business not found',
      });
    }

    const supplier = new Supplier({
      business,
      name: name.trim(),
      phone,
      address,
      notes,
    });

    const savedSupplier = await supplier.save();

    res.status(201).json({
      success: true,
      message: 'Supplier created successfully',
      data: savedSupplier,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Get suppliers by business ID
exports.getSuppliersByBusiness = async (req, res) => {
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

    const suppliers = await Supplier.find({ business: businessId }).populate('business');

    res.status(200).json({
      success: true,
      data: suppliers,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Update supplier by ID
exports.updateSupplier = async (req, res) => {
  try {
    const { id } = req.params;
    const { business, name, phone, address, notes } = req.body;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    const supplier = await Supplier.findById(id);

    if (!supplier) {
      return res.status(404).json({
        message: 'Supplier not found',
      });
    }

    // Verify business ownership
    const isOwner = await verifyBusinessOwnership(supplier.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Supplier not found',
      });
    }

    // If business is being updated, verify it exists
    if (business !== undefined) {
      if (!mongoose.Types.ObjectId.isValid(business)) {
        return res.status(400).json({
          message: 'Invalid ID format',
        });
      }
      
      // Verify business ownership
      const isNewOwner = await verifyBusinessOwnership(business, req.user._id);
      if (!isNewOwner) {
        return res.status(404).json({
          message: 'Business not found',
        });
      }
      supplier.business = business;
    }

    // Update fields if provided
    if (name !== undefined) supplier.name = name.trim();
    if (phone !== undefined) supplier.phone = phone;
    if (address !== undefined) supplier.address = address;
    if (notes !== undefined) supplier.notes = notes;

    const updatedSupplier = await supplier.save();

    res.status(200).json({
      success: true,
      message: 'Supplier updated successfully',
      data: updatedSupplier,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};

// Delete supplier by ID
exports.deleteSupplier = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Find first — we need the business field to verify ownership
    // before touching the document (find-then-verify-then-delete).
    const supplier = await Supplier.findById(id);

    if (!supplier) {
      return res.status(404).json({
        message: 'Supplier not found',
      });
    }

    // Verify business ownership BEFORE deleting
    const isOwner = await verifyBusinessOwnership(supplier.business, req.user._id);
    if (!isOwner) {
      return res.status(404).json({
        message: 'Supplier not found',
      });
    }

    await Supplier.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Supplier deleted successfully',
      data: supplier,
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};