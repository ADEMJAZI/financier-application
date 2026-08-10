const express = require('express');
const cashFlowController = require('../controllers/cashFlow.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Get cash flow report by business ID
router.get('/business/:businessId', cashFlowController.getCashFlowReport);

module.exports = router;