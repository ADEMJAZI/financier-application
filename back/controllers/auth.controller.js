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

    // Generate email verification token
    const rawVerifyToken = crypto.randomBytes(32).toString('hex');
    const hashedVerifyToken = hashToken(rawVerifyToken);

    const user = await User.create({
      name,
      email,
      password,
      emailVerificationToken: hashedVerifyToken,
      emailVerificationExpires: new Date(Date.now() + 24 * 60 * 60 * 1000), // 24 h
    });

    // Issue access + refresh tokens
    const accessToken = generateAccessToken(user._id);
    const refreshToken = generateRefreshToken(user._id);

    // Store hashed refresh token — supports multiple devices/sessions
    user.refreshTokens.push(hashToken(refreshToken));
    await user.save();

    // Send verification email (non-blocking)
    const verificationLink = `${process.env.FRONTEND_URL}/verify-email?token=${rawVerifyToken}`;
    sendVerificationEmail(user.email, user.name, verificationLink).then((sent) => {
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
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({ message: 'Token is required' });
    }

    const hashedToken = hashToken(token);

    const user = await User.findOne({
      emailVerificationToken: hashedToken,
      emailVerificationExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired verification link' });
    }

    user.isEmailVerified = true;
    user.emailVerificationToken = null;
    user.emailVerificationExpires = null;
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

    const rawToken = crypto.randomBytes(32).toString('hex');

    user.emailVerificationToken = hashToken(rawToken);
    user.emailVerificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);
    await user.save();

    const verificationLink = `${process.env.FRONTEND_URL}/verify-email?token=${rawToken}`;
    sendVerificationEmail(user.email, user.name, verificationLink).then((sent) => {
      if (!sent) console.warn(`Failed to resend verification email to ${user.email}`);
    });

    res.status(200).json({ success: true, message: 'Verification email sent' });
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Forgot password ──────────────────────────────────────────────────────────

exports.forgotPassword = async (req, res) => {
  const safeResponse = {
    success: true,
    message: 'If an account exists with this email, a reset link has been sent',
  };

  try {
    const { email } = req.body;

    if (!email) {
      return res.status(400).json({ message: 'Email is required' });
    }

    const user = await User.findOne({ email: email.toLowerCase() });

    if (!user) {
      return res.status(200).json(safeResponse);
    }

    const rawToken = crypto.randomBytes(32).toString('hex');

    user.passwordResetToken = hashToken(rawToken);
    user.passwordResetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1 h
    await user.save();

    const resetLink = `${process.env.FRONTEND_URL}/reset-password?token=${rawToken}`;
    sendPasswordResetEmail(user.email, user.name, resetLink).then((sent) => {
      if (!sent) console.warn(`Failed to send password reset email to ${user.email}`);
    });

    res.status(200).json(safeResponse);
  } catch (error) {
    res.status(500).json({ message: error.message });
  }
};

// ─── Reset password ───────────────────────────────────────────────────────────

exports.resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    if (!token || !newPassword) {
      return res.status(400).json({ message: 'Token and newPassword are required' });
    }

    if (newPassword.length < 6) {
      return res.status(400).json({ message: 'Password must be at least 6 characters' });
    }

    const user = await User.findOne({
      passwordResetToken: hashToken(token),
      passwordResetExpires: { $gt: Date.now() },
    });

    if (!user) {
      return res.status(400).json({ message: 'Invalid or expired reset link' });
    }

    user.password = newPassword;
    user.passwordResetToken = null;
    user.passwordResetExpires = null;
    // Invalidate ALL existing sessions — force re-login everywhere
    user.refreshTokens = [];
    await user.save();

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
