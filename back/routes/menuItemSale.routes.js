const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  recordSale,
  getSalesByBusiness,
  getDailySummary,
  getDailyProfitReport,
  deleteSale,
} = require('../controllers/menuItemSale.controller');

// Protect all routes
router.use(protect);

// Record a menu item sale
router.post('/', recordSale);

// Get sales by business ID with optional date range
router.get('/business/:businessId', getSalesByBusiness);

// Get daily summary for a specific date
router.get('/business/:businessId/daily-summary', getDailySummary);

// Get daily profit report (revenue - expenses)
router.get('/business/:businessId/daily-profit', getDailyProfitReport);

// Delete a sale (undo)
router.delete('/:id', deleteSale);

module.exports = router;
