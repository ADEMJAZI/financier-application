const Business = require('../models/Business');
const { logAudit } = require('../middleware/auditLogger');
const mongoose = require('mongoose');

// Create a new business
exports.createBusiness = async (req, res) => {
  try {
    const { name, type, businessType, location, description } = req.body;

    // Validate required fields
    if (!name || !type || !businessType || !location) {
      return res.status(400).json({
        success: false,
        message: 'Required fields: name, type, businessType, location',
      });
    }

    // Validate businessType
    if (!['manufacturing', 'resale'].includes(businessType)) {
      return res.status(400).json({
        success: false,
        message: 'businessType must be either manufacturing or resale',
      });
    }

    const business = new Business({
      owner: req.user._id, // Automatically set from JWT
      name,
      type,
      businessType,
      location,
      description,
    });

    const savedBusiness = await business.save();

    res.status(201).json({
      success: true,
      message: 'Business created successfully',
      data: savedBusiness,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get all businesses
exports.getBusinesses = async (req, res) => {
  try {
    // Only return businesses owned by the authenticated user
    const businesses = await Business.find({ owner: req.user._id });

    res.status(200).json({
      success: true,
      data: businesses,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Get business by ID
exports.getBusinessById = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ID format',
      });
    }

    const business = await Business.findById(id);

    if (!business) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    // Verify ownership
    if (business.owner.toString() !== req.user._id.toString()) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    res.status(200).json({
      success: true,
      data: business,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Update business by ID
exports.updateBusiness = async (req, res) => {
  try {
    const { id } = req.params;
    const { name, type, businessType, location, description } = req.body;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ID format',
      });
    }

    const business = await Business.findById(id);

    if (!business) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    // Verify ownership
    if (business.owner.toString() !== req.user._id.toString()) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    // Update fields if provided
    if (name !== undefined) business.name = name;
    if (type !== undefined) business.type = type;
    if (businessType !== undefined) {
      if (!['manufacturing', 'resale'].includes(businessType)) {
        return res.status(400).json({
          success: false,
          message: 'businessType must be either manufacturing or resale',
        });
      }
      business.businessType = businessType;
    }
    if (location !== undefined) business.location = location;
    if (description !== undefined) business.description = description;

    const updatedBusiness = await business.save();

    res.status(200).json({
      success: true,
      message: 'Business updated successfully',
      data: updatedBusiness,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};

// Delete business by ID
exports.deleteBusiness = async (req, res) => {
  try {
    const { id } = req.params;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(id)) {
      return res.status(400).json({
        success: false,
        message: 'Invalid ID format',
      });
    }

    const business = await Business.findById(id);

    if (!business) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    // Verify ownership
    if (business.owner.toString() !== req.user._id.toString()) {
      return res.status(404).json({
        success: false,
        message: 'Business not found',
      });
    }

    await Business.findByIdAndDelete(id);

    res.status(200).json({
      success: true,
      message: 'Business deleted successfully',
      data: business,
    });
  } catch (error) {
    res.status(500).json({
      success: false,
      message: error.message,
    });
  }
};
