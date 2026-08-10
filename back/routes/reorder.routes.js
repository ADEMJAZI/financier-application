const express = require('express');
const reorderController = require('../controllers/reorder.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Get reorder suggestions by business ID
router.get('/business/:businessId', reorderController.getReorderSuggestions);

// Update reorder settings for a product
router.patch('/:productId/reorder-settings', reorderController.updateReorderSettings);

module.exports = router;