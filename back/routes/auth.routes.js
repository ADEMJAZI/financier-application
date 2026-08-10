const express = require('express');
const authController = require('../controllers/auth.controller');
const { protect } = require('../middleware/authMiddleware');
const { authLimiter } = require('../middleware/rateLimiter');

const router = express.Router();

// ─── Public — rate limited (brute-force sensitive) ────────────────────────────
router.post('/register', authLimiter, authController.register);
router.post('/login',    authLimiter, authController.login);

// ─── Token management (public — access token may be expired) ─────────────────
router.post('/refresh', authController.refreshAccessToken);
router.post('/logout',  authController.logout);

// ─── Protected ────────────────────────────────────────────────────────────────
router.get('/me', protect, authController.getMe);

// ─── Email verification ───────────────────────────────────────────────────────
router.post('/verify-email',        authController.verifyEmail);
router.post('/resend-verification', authLimiter, protect, authController.resendVerificationEmail);

// ─── Password reset ───────────────────────────────────────────────────────────
router.post('/forgot-password', authLimiter, authController.forgotPassword);
router.post('/reset-password',  authLimiter, authController.resetPassword);

module.exports = router;
