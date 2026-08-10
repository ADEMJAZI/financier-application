'use strict';

const express      = require('express');
const ctrl         = require('../controllers/ai.controller');
const { protect }  = require('../middleware/authMiddleware');

const router = express.Router();
router.use(protect);

// ── Parse expense from natural language (no save) ─────────────────────────
router.post('/parse-expense',                    ctrl.parseExpense);

// ── Weekly / monthly narrative summary ───────────────────────────────────
router.get('/summary/:businessId',               ctrl.generateSummary);

// ── Anomaly detection (rule-based + AI explanation) ──────────────────────
router.get('/anomalies/:businessId',             ctrl.detectAnomalies);

// ── Dashboard insights (rule-based, no extra AI call) ────────────────────
router.get('/insights/:businessId',              ctrl.generateInsights);

// ── Pricing & sales advisor ───────────────────────────────────────────────
router.get('/pricing-advice/:businessId',        ctrl.pricingAdvice);

// ── AI business assistant chat ────────────────────────────────────────────
router.post('/chat/:businessId',                 ctrl.chat);

// ── Receipt / invoice image analysis ─────────────────────────────────────
router.post('/analyze-receipt',                  ctrl.analyzeReceipt);

// ── What-if pricing simulator ─────────────────────────────────────────────
router.post('/simulate-pricing/:businessId',     ctrl.simulatePricing);

// ── Internal: Gemini quota stats (no ownership check needed) ─────────────
router.get('/quota-stats',                       ctrl.quotaStats);

module.exports = router;
