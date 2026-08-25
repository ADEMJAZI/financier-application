const express = require('express');
const authController = require('../controllers/auth.controller');
const { protect } = require('../middleware/authMiddleware');
const { authLimiter, generalApiLimiter } = require('../middleware/rateLimiter');

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
// verify-email is protected: the user is already authenticated from registration,
// and the OTP is validated against their own stored hash — no token search needed.
router.post('/verify-email',        authLimiter, protect, authController.verifyEmail);
router.post('/resend-verification', authLimiter, protect, authController.resendVerificationEmail);

// ─── Password reset ───────────────────────────────────────────────────────────
// Step 1: request a 6-digit OTP code via email (public, rate limited)
router.post('/forgot-password',   authLimiter, authController.forgotPassword);
// Step 2: verify the OTP — returns a short-lived resetSessionToken (public, rate limited)
router.post('/verify-reset-code', authLimiter, authController.verifyResetCode);
// Step 3: submit newPassword + resetSessionToken — the token itself is the gate,
// so general rate limiting is sufficient here (no need for the stricter authLimiter)
router.post('/reset-password',    generalApiLimiter, authController.resetPassword);

module.exports = router;
