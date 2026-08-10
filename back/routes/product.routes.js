const express = require('express');
const productController = require('../controllers/product.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Create product
router.post('/', productController.createProduct);

// Get products by business ID
router.get('/business/:businessId', productController.getProductsByBusiness);

// Get product by ID
router.get('/:id', productController.getProductById);

// Update product by ID
router.put('/:id', productController.updateProduct);

// Restock product
router.patch('/:id/restock', productController.restockProduct);

// Delete product by ID
router.delete('/:id', productController.deleteProduct);

module.exports = router;
