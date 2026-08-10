const express = require('express');
const reserveController = require('../controllers/reserve.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Create reserve
router.post('/', reserveController.createReserve);

// Get reserves by business ID
router.get('/business/:businessId', reserveController.getReservesByBusiness);

// Deposit to reserve
router.post('/:id/deposit', reserveController.deposit);

// Withdraw from reserve
router.post('/:id/withdraw', reserveController.withdraw);

// Delete reserve by ID
router.delete('/:id', reserveController.deleteReserve);

module.exports = router;