const AuditLog = require('../models/AuditLog');

const logAudit = async (business, collectionName, documentId, action, changes, performedBy = 'system') => {
  try {
    const auditLog = new AuditLog({
      business,
      collectionName,
      documentId,
      action,
      changes,
      performedBy,
    });

    await auditLog.save();
  } catch (error) {
    // Do not throw error - audit failure should not break main operations
    console.error('Audit log error:', error.message);
  }
};

module.exports = { logAudit };