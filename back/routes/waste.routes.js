const express = require('express');
const wasteController = require('../controllers/waste.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Create waste
router.post('/', wasteController.createWaste);

// Get waste by business ID
router.get('/business/:businessId', wasteController.getWasteByBusiness);

// Get waste total by business ID
router.get('/business/:businessId/total', wasteController.getWasteTotalByBusiness);

// Delete waste by ID
router.delete('/:id', wasteController.deleteWaste);

module.exports = router;