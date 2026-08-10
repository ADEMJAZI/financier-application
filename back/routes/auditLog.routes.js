const express = require('express');
const auditLogController = require('../controllers/auditLog.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Get audit logs by business ID
router.get('/business/:businessId', auditLogController.getAuditLogsByBusiness);

module.exports = router;