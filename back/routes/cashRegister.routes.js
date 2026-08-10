const express = require('express');
const cashRegisterController = require('../controllers/cashRegister.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Open register
router.post('/', cashRegisterController.openRegister);

// Get registers by business ID
router.get('/business/:businessId', cashRegisterController.getRegistersByBusiness);

// Get register by ID
router.get('/:id', cashRegisterController.getRegisterById);

// Close register
router.patch('/:id/close', cashRegisterController.closeRegister);

// Delete register by ID
router.delete('/:id', cashRegisterController.deleteRegister);

module.exports = router;