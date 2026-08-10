const express = require('express');
const supplierPurchaseController = require('../controllers/supplierPurchase.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Get purchases by business ID
router.get('/business/:businessId', supplierPurchaseController.getPurchasesByBusiness);

module.exports = router;