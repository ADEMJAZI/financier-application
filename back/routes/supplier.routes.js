const express = require('express');
const supplierController = require('../controllers/supplier.controller');
const supplierPurchaseController = require('../controllers/supplierPurchase.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Create supplier
router.post('/', supplierController.createSupplier);

// Get suppliers by business ID
router.get('/business/:businessId', supplierController.getSuppliersByBusiness);

// Update supplier by ID
router.put('/:id', supplierController.updateSupplier);

// Delete supplier by ID
router.delete('/:id', supplierController.deleteSupplier);

// Record purchase for supplier
router.post('/:id/purchases', supplierPurchaseController.recordPurchase);

// Get purchases by supplier ID
router.get('/:id/purchases', supplierPurchaseController.getPurchasesBySupplier);

module.exports = router;

// Note: For purchases by business, use separate route at /api/purchases/business/:businessId