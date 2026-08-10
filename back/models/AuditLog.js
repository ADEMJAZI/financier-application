const mongoose = require('mongoose');

const auditLogSchema = new mongoose.Schema(
  {
    business: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Business',
      required: [true, 'Business ID is required'],
    },
    collectionName: {
      type: String,
      required: [true, 'Collection name is required'],
    },
    documentId: {
      type: mongoose.Schema.Types.ObjectId,
      required: [true, 'Document ID is required'],
    },
    action: {
      type: String,
      enum: ['create', 'update', 'delete'],
      required: [true, 'Action is required'],
    },
    changes: {
      type: mongoose.Schema.Types.Mixed,
    },
    performedBy: {
      type: String,
      default: 'system',
    },
    performedAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

module.exports = mongoose.model('AuditLog', auditLogSchema);