const express = require('express');
const router = express.Router();
const { protect } = require('../middleware/authMiddleware');
const {
  createOrder,
  getOrdersByBusiness,
  getOrderById,
  voidOrder,
  getDailySummary,
  getDailyProfitReport,
} = require('../controllers/order.controller');

// Protect all routes
router.use(protect);

// ── Business-scoped routes (must come before /:id to avoid param collision) ──

// GET /api/orders/business/:businessId/daily-summary?date=
router.get('/business/:businessId/daily-summary', getDailySummary);

// GET /api/orders/business/:businessId/daily-profit?date=
router.get('/business/:businessId/daily-profit', getDailyProfitReport);

// GET /api/orders/business/:businessId?from=&to=&status=
router.get('/business/:businessId', getOrdersByBusiness);

// ── Order-level routes ────────────────────────────────────────────────────────

// POST /api/orders  — Create a new order / invoice
router.post('/', createOrder);

// GET /api/orders/:id  — Get a single order (full invoice detail)
router.get('/:id', getOrderById);

// PATCH /api/orders/:id/void  — Void a completed order
router.patch('/:id/void', voidOrder);

module.exports = router;
