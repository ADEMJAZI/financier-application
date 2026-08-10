const express = require('express');
const businessController = require('../controllers/business.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Create business
router.post('/', businessController.createBusiness);

// Get all businesses
router.get('/', businessController.getBusinesses);

// Get business by ID
router.get('/:id', businessController.getBusinessById);

// Update business by ID
router.put('/:id', businessController.updateBusiness);

// Delete business by ID
router.delete('/:id', businessController.deleteBusiness);

module.exports = router;
