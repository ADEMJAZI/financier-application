const AuditLog = require('../models/AuditLog');
const Business = require('../models/Business');
const mongoose = require('mongoose');
const { verifyBusinessOwnership } = require('../utils/verifyBusinessOwnership');

// Get audit logs by business
exports.getAuditLogsByBusiness = async (req, res) => {
  try {
    const { businessId } = req.params;
    const { collectionName, documentId, from, to, page = 1, limit = 50 } = req.query;

    // Validate ID format
    if (!mongoose.Types.ObjectId.isValid(businessId)) {
      return res.status(400).json({
        message: 'Invalid ID format',
      });
    }

    // Validate documentId if provided
    if (documentId && !mongoose.Types.ObjectId.isValid(documentId)) {
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

    // Validate pagination params
    const pageNum = Math.max(1, parseInt(page));
    const limitNum = Math.min(200, Math.max(1, parseInt(limit))); // Max 200, default 50

    // Build query
    let query = { business: businessId };

    if (collectionName) {
      query.collectionName = collectionName;
    }

    if (documentId) {
      query.documentId = documentId;
    }

    if (from || to) {
      query.performedAt = {};
      if (from) {
        const fromDate = new Date(from);
        if (!isNaN(fromDate.getTime())) {
          query.performedAt.$gte = fromDate;
        }
      }
      if (to) {
        const toDate = new Date(to);
        if (!isNaN(toDate.getTime())) {
          query.performedAt.$lte = toDate;
        }
      }
    }

    // Calculate skip
    const skip = (pageNum - 1) * limitNum;

    // Get total count for pagination
    const total = await AuditLog.countDocuments(query);

    // Get audit logs
    const auditLogs = await AuditLog.find(query)
      .populate('business', 'name')
      .sort({ performedAt: -1 })
      .skip(skip)
      .limit(limitNum);

    res.status(200).json({
      success: true,
      data: auditLogs,
      pagination: {
        page: pageNum,
        limit: limitNum,
        total,
        totalPages: Math.ceil(total / limitNum),
      },
    });
  } catch (error) {
    res.status(500).json({
      message: error.message,
    });
  }
};