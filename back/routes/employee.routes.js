const express = require('express');
const employeeController = require('../controllers/employee.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Create employee
router.post('/', employeeController.createEmployee);

// Get employees by business ID
router.get('/business/:businessId', employeeController.getEmployeesByBusiness);

// Update employee by ID
router.put('/:id', employeeController.updateEmployee);

// Delete employee by ID
router.delete('/:id', employeeController.deleteEmployee);

// Record salary payment
router.post('/:id/payments', employeeController.recordSalaryPayment);

// Deactivate employee
router.patch('/:id/deactivate', employeeController.deactivateEmployee);

module.exports = router;