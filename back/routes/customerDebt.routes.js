const express = require('express');
const customerDebtController = require('../controllers/customerDebt.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Create debt
router.post('/', customerDebtController.createDebt);

// Get debts by business ID
router.get('/business/:businessId', customerDebtController.getDebtsByBusiness);

// Get debt by ID
router.get('/:id', customerDebtController.getDebtById);

// Add payment to debt
router.post('/:id/payments', customerDebtController.addPayment);

// Delete debt by ID
router.delete('/:id', customerDebtController.deleteDebt);

module.exports = router;