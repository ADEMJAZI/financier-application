const Business = require('../models/Business');
const mongoose = require('mongoose');

// Helper function to verify business ownership
const verifyBusinessOwnership = async (businessId, userId) => {
  try {
    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return false;
    }

    // Fetch business
    const business = await Business.findById(businessId);

    // Check if business exists and belongs to user
    if (!business || business.owner.toString() !== userId.toString()) {
      return false;
    }

    return true;
  } catch (error) {
    return false;
  }
};

module.exports = { verifyBusinessOwnership };