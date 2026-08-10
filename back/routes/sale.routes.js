const express = require('express');
const saleController = require('../controllers/sale.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

router.use(protect);

// Record a sale
router.post('/', saleController.recordSale);

// Get sales by business
router.get('/business/:businessId', saleController.getSalesByBusiness);

// Get daily summary
router.get('/business/:businessId/daily-summary', saleController.getDailySummary);

// Get daily profit report
router.get('/business/:businessId/daily-profit', saleController.getDailyProfitReport);

// Delete sale (undo)
router.delete('/:id', saleController.deleteSale);

module.exports = router;
