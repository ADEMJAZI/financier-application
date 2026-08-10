const express = require('express');
const expenseController = require('../controllers/expense.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Protect all routes
router.use(protect);

// Create expense from natural language (AI-powered) — must be before '/:id' routes
router.post('/from-text', expenseController.createExpenseFromText);

// Create expense
router.post('/', expenseController.createExpense);

// Get expenses by business ID
router.get('/business/:businessId', expenseController.getExpensesByBusiness);

// Update expense by ID
router.put('/:id', expenseController.updateExpense);

// Delete expense by ID
router.delete('/:id', expenseController.deleteExpense);

module.exports = router;