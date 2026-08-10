const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  createMenuItem,
  getMenuItemsByBusiness,
  getMenuItemById,
  updateMenuItem,
  deactivateMenuItem,
  deleteMenuItem,
} = require('../controllers/menuItem.controller');

// Protect all routes
router.use(protect);

// Create a new menu item
router.post('/', createMenuItem);

// Get menu items by business ID
router.get('/business/:businessId', getMenuItemsByBusiness);

// Get a single menu item by ID (with populated recipe)
router.get('/:id', getMenuItemById);

// Update menu item by ID
router.put('/:id', updateMenuItem);

// Deactivate menu item (soft delete)
router.patch('/:id/deactivate', deactivateMenuItem);

// Delete menu item (hard delete, only if no sales)
router.delete('/:id', deleteMenuItem);

module.exports = router;
