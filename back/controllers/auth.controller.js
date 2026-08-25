const User = require('../models/User');
const jwt = require('jsonwebtoken');
const crypto = require('crypto');
const { sendVerificationEmail, sendPasswordResetEmail, sendPasswordChangeConfirmation } = require('../utils/emailService');

// ─── Token helpers ────────────────────────────────────────────────────────────

/**
 * Short-lived access token (15 min).
 * Used by the `protect` middleware to authenticate every API request.
 */
const generateAccessToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_SECRET, { expiresIn: '15m' });
};

/**
 * Long-lived refresh token (30 days), signed with a SEPARATE secret.
 * Stored as a sha256 hash in user.refreshTokens so the raw value is
 * never persisted — if the DB is compromised, stored hashes can't be
 * replayed without knowing the original JWT (which also requires the secret).
 */
const generateRefreshToken = (id) => {
  return jwt.sign({ id }, process.env.JWT_REFRESH_SECRET, { expiresIn: '30d' });
};

/** sha256 hash used to store/compare refresh tokens without saving the raw JWT */
const hashToken = (token) => crypto.createHash('sha256').update(token).digest('hex');

// ─── Register ─────────────────────────────────────────────────────────────────

exports.register = async (req, res) => {
  try {
    const { name, email, password } = req.body;

    if (!name || !email || !password) {
      return res.status(400).json({ message: 'name, email and password are required' });
    }

    const userExists = await User.findOne({ email: email.toLowerCase() });
    if (userExists) {
      return res.status(409).json({ message: 'Email already registered' });
    }

    // Generate a 6-digit numeric OTP code
    const rawOtp = Math.floor(100000 + Math.random() * 900000).toString();
    const hashedOtp = hashToken(rawOtp);

    const user = await User.create({
      name,
      email,
      password,
      emailVerificationToken: hashedOtp,
      emailVerificationExpires: new Date(Date.now() + 10 * 60 * 1000), // 10 min
      emailVerificationAttempts: 0,
    });

    // Issue access + refresh tokens
    const accessToken = generateAccessToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    // Store hashed refresh token — supports multiple devices/sessions
    user.refreshTokens.push(hashToken(refreshToken));
    await user.save();

    // Send OTP email (non-blocking — registration response is not delayed)
    sendVerificationEmail(user.email, user.name, rawOtp).then((sent) => {
      if (!sent) console.warn(`Failed to send verification email to ${user.email} during registration`);
    });

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        isEmailVerified: user.isEmailVerified,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Login ────────────────────────────────────────────────────────────────────

exports.login = async (req, res) => {
  try {
    const { email, password } = req.body;

    if (!email || !password) {
      return res.status(400).json({ message: 'email and password are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() }).select('+password');

    if (!user || !(await user.comparePassword(password))) {
      return res.status(401).json({ message: 'Invalid credentials' });
    }

    // Issue access + refresh tokens
    const accessToken = generateAccessToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    // Append new session's hashed refresh token (keeps other sessions alive)
    user.refreshTokens.push(hashToken(refreshToken));
    await user.save();

    res.status(200).json({
      success: true,
      message: 'Login successful',
      accessToken,
      refreshToken,
      user: {
        id: user._id,
        name: user.name,
        email: user.email,
        isEmailVerified: user.isEmailVerified,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Refresh access token ─────────────────────────────────────────────────────

exports.refreshAccessToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ message: 'refreshToken is required' });
    }

    // Verify signature and expiry first — catches tampered or expired tokens
    // before we even hit the database
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    } catch {
      return res.status(401).json({ message: 'Invalid or expired refresh token' });
    }

    const user = await User.findById(decoded.id);
    if (!user) {
      return res.status(401).json({ message: 'User not found' });
    }

    const incomingHash = hashToken(refreshToken);

    // Check the token is still in the user's active sessions array.
    // If it's missing, the token was already used (rotation) or revoked
    // (logout) — reject to prevent reuse attacks.
    if (!user.refreshTokens.includes(incomingHash)) {
      return res.status(401).json({ message: 'Refresh token has been revoked' });
    }

    // ── Refresh token rotation ──
    // Remove the old hash and issue a brand-new refresh token so each token
    // can only be used once. If a stolen token is replayed after the
    // legitimate client already rotated it, the hash won't be found above.
    user.refreshTokens = user.refreshTokens.filter((t) => t !== incomingHash);

    const newAccessToken = generateAccessToken(user._id);
    const newRefreshToken = generateRefreshToken(user._id);

    user.refreshTokens.push(hashToken(newRefreshToken));
    await user.save();

    res.status(200).json({
      success: true,
      accessToken: newAccessToken,
      refreshToken: newRefreshToken,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Logout ───────────────────────────────────────────────────────────────────

exports.logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;

    if (!refreshToken) {
      return res.status(400).json({ message: 'refreshToken is required' });
    }

    // Verify signature so we can extract the user id — we do NOT reject on
    // expiry here; a user should still be able to logout with an expired
    // refresh token (it just removes it from the DB so it can't be reused
    // if somehow un-expired later).
    let decoded;
    try {
      decoded = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET, {
        ignoreExpiration: true,
      });
    } catch {
      // Tampered token — nothing to revoke, but return 200 so the client
      // always ends up in a logged-out state without leaking information.
      return res.status(200).json({ success: true, message: 'Logged out' });
    }

    const user = await User.findById(decoded.id);
    if (user) {
      const incomingHash = hashToken(refreshToken);
      user.refreshTokens = user.refreshTokens.filter((t) => t !== incomingHash);
      await user.save();
    }

    res.status(200).json({ success: true, message: 'Logged out' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Get current user ─────────────────────────────────────────────────────────

exports.getMe = async (req, res) => {
  try {
    const user = await User.findById(req.user._id).select('-password');

    res.status(200).json({
      success: true,
      data: {
        id: user._id,
        name: user.name,
        email: user.email,
        isEmailVerified: user.isEmailVerified,
        createdAt: user.createdAt,
      },
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Verify email ─────────────────────────────────────────────────────────────

exports.verifyEmail = async (req, res) => {
  try {
    const { code } = req.body;

    if (!code) {
      return res.status(400).json({ message: 'code is required' });
    }

    // Operates on the authenticated user — no token search across all users.
    // req.user is populated by the protect middleware on this route.
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: 'Email is already verified' });
    }

    // Guard: no code on record (never generated, or already cleared after success)
    if (!user.emailVerificationToken || !user.emailVerificationExpires) {
      return res.status(400).json({ message: 'No verification code found. Please request a new one.' });
    }

    // Check expiry before evaluating the code — avoids incrementing attempts
    // on a code the user can no longer act on anyway
    if (user.emailVerificationExpires < Date.now()) {
      // Clear the stale code so the client knows a resend is needed
      user.emailVerificationToken = null;
      user.emailVerificationExpires = null;
      user.emailVerificationAttempts = 0;
      await user.save();
      return res.status(400).json({ message: 'Code expired, please request a new one' });
    }

    // Brute-force guard: 5 failed attempts invalidates the current code
    if (user.emailVerificationAttempts >= 5) {
      user.emailVerificationToken = null;
      user.emailVerificationExpires = null;
      user.emailVerificationAttempts = 0;
      await user.save();
      return res.status(429).json({ message: 'Too many failed attempts, please request a new code' });
    }

    // Compare hashed codes
    const hashedInput = hashToken(code.trim());
    if (hashedInput !== user.emailVerificationToken) {
      user.emailVerificationAttempts += 1;

      // If this increment just hit the limit, invalidate immediately
      if (user.emailVerificationAttempts >= 5) {
        user.emailVerificationToken = null;
        user.emailVerificationExpires = null;
        user.emailVerificationAttempts = 0;
        await user.save();
        return res.status(429).json({ message: 'Too many failed attempts, please request a new code' });
      }

      await user.save();
      const remaining = 5 - user.emailVerificationAttempts;
      return res.status(400).json({
        message: `Invalid code. ${remaining} attempt${remaining === 1 ? '' : 's'} remaining.`,
      });
    }

    // Code is correct — mark verified and clear OTP fields
    user.isEmailVerified = true;
    user.emailVerificationToken = null;
    user.emailVerificationExpires = null;
    user.emailVerificationAttempts = 0;
    await user.save();

    res.status(200).json({ success: true, message: 'Email verified successfully' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Resend verification email (protected) ────────────────────────────────────

exports.resendVerificationEmail = async (req, res) => {
  try {
    const user = await User.findById(req.user._id);

    if (!user) {
      return res.status(404).json({ message: 'User not found' });
    }

    if (user.isEmailVerified) {
      return res.status(400).json({ message: 'Email is already verified' });
    }

    // Generate a fresh 6-digit OTP — invalidates any previous code
    const rawOtp = Math.floor(100000 + Math.random() * 900000).toString();

    user.emailVerificationToken = hashToken(rawOtp);
    user.emailVerificationExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 min
    user.emailVerificationAttempts = 0;
    await user.save();

    sendVerificationEmail(user.email, user.name, rawOtp).then((sent) => {
      if (!sent) console.warn(`Failed to resend verification email to ${user.email}`);
    });

    res.status(200).json({ success: true, message: 'Verification code sent' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Forgot password ──────────────────────────────────────────────────────────

exports.forgotPassword = async (req, res) => {
  // Always return the same message — prevents email enumeration.
  const safeResponse = {
    success: true,
    message: 'If an account exists with this email, a reset code has been sent',
  };

  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      // Deliberately indistinguishable from success — do not reveal existence
      return res.status(200).json(safeResponse);
    }

    // Generate a 6-digit numeric OTP
    const rawOtp = Math.floor(100000 + Math.random() * 900000).toString();

    user.passwordResetCode = hashToken(rawOtp);
    user.passwordResetExpires = new Date(Date.now() + 10 * 60 * 1000); // 10 min
    user.passwordResetAttempts = 0;
    await user.save();

    // Send OTP email (non-blocking — response is not delayed)
    sendPasswordResetEmail(user.email, user.name, rawOtp).then((sent) => {
      if (!sent) console.warn(`Failed to send password reset email to ${user.email}`);
    });

    res.status(200).json(safeResponse);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Verify reset code ────────────────────────────────────────────────────────

exports.verifyResetCode = async (req, res) => {
  // Use the same generic error for every failure path — prevents both email
  // enumeration and leaking whether a code was ever issued for this address.
  const genericError = { message: 'Invalid or expired code' };

  try {
    const { email, code } = req.body;

    if (!email || !code) {
      return res.status(400).json({ message: 'email and code are required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });

    // Treat a missing user identically to a wrong code — no enumeration
    if (!user) {
      return res.status(400).json(genericError);
    }

    // No code on record (never requested, or already cleared)
    if (!user.passwordResetCode || !user.passwordResetExpires) {
      return res.status(400).json(genericError);
    }

    // Check expiry before evaluating the code — avoids burning an attempt
    // on a code the user can no longer act on anyway
    if (user.passwordResetExpires < Date.now()) {
      user.passwordResetCode = null;
      user.passwordResetExpires = null;
      user.passwordResetAttempts = 0;
      await user.save();
      return res.status(400).json(genericError);
    }

    // Brute-force guard: 5 failed attempts invalidates the current code
    if (user.passwordResetAttempts >= 5) {
      user.passwordResetCode = null;
      user.passwordResetExpires = null;
      user.passwordResetAttempts = 0;
      await user.save();
      return res.status(429).json({ message: 'Too many failed attempts, please request a new code' });
    }

    // Compare hashed codes
    const hashedInput = hashToken(code.trim());
    if (hashedInput !== user.passwordResetCode) {
      user.passwordResetAttempts += 1;

      // If this increment just hit the limit, invalidate immediately
      if (user.passwordResetAttempts >= 5) {
        user.passwordResetCode = null;
        user.passwordResetExpires = null;
        user.passwordResetAttempts = 0;
        await user.save();
        return res.status(429).json({ message: 'Too many failed attempts, please request a new code' });
      }

      await user.save();
      const remaining = 5 - user.passwordResetAttempts;
      return res.status(400).json({
        message: `Invalid code. ${remaining} attempt${remaining === 1 ? '' : 's'} remaining.`,
      });
    }

    // Code is correct — clear it immediately (single-use) before responding
    user.passwordResetCode = null;
    user.passwordResetExpires = null;
    user.passwordResetAttempts = 0;
    await user.save();

    // Issue a short-lived reset session token scoped to password reset only.
    // This proves code ownership on the next step without making the user
    // re-enter the code — payload includes purpose so it cannot be reused
    // as a general access token.
    const resetSessionToken = jwt.sign(
      { id: user._id, purpose: 'password_reset' },
      process.env.JWT_SECRET,
      { expiresIn: '5m' },
    );

    res.status(200).json({
      success: true,
      message: 'Code verified successfully',
      resetSessionToken,
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Reset password ───────────────────────────────────────────────────────────

exports.resetPassword = async (req, res) => {
  try {
    const { resetSessionToken, newPassword } = req.body;

    if (!resetSessionToken || !newPassword) {
      return res.status(400).json({ message: 'resetSessionToken and newPassword are required' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    // Verify the short-lived reset session token and confirm its purpose.
    // Any tampering, expiry, or wrong secret rejects here.
    let decoded;
    try {
      decoded = jwt.verify(resetSessionToken, process.env.JWT_SECRET);
    } catch {
      return res.status(401).json({ message: 'Reset session expired, please start over' });
    }

    if (decoded.purpose !== 'password_reset') {
      return res.status(401).json({ message: 'Reset session expired, please start over' });
    }

    const user = await User.findById(decoded.id);
    if (!user) {
      return res.status(401).json({ message: 'Reset session expired, please start over' });
    }

    user.password = newPassword;
    // Invalidate ALL existing sessions — force re-login everywhere
    user.refreshTokens = [];
    await user.save();

    // Fire-and-forget — don't block the response on email delivery
    sendPasswordChangeConfirmation(user.email, user.name).catch((err) => {
      console.error('Failed to send password change confirmation:', err.message);
    });

    res.status(200).json({
      success: true,
      message: 'Password reset successfully. Please log in with your new password.',
    });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};
