const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');

const userSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: [true, 'Name is required'],
      trim: true,
    },
    email: {
      type: String,
      required: [true, 'Email is required'],
      unique: true,
      trim: true,
      lowercase: true,
      match: [/^\S+@\S+\.\S+$/, 'Please provide a valid email address'],
    },
    password: {
      type: String,
      required: [true, 'Password is required'],
      minlength: [6, 'Password must be at least 6 characters'],
      select: false, // Don't return password in queries by default
    },
    // Email verification fields
    isEmailVerified: {
      type: Boolean,
      default: false,
    },
    // Stores sha256 hash of the 6-digit OTP code (never the raw code).
    // Reused for both initial registration and resend flows.
    // Expires after 10 minutes — appropriate for short numeric OTPs.
    emailVerificationToken: {
      type: String,
      default: null,
    },
    emailVerificationExpires: {
      type: Date,
      default: null,
    },
    // Tracks consecutive failed code-entry attempts since last code generation.
    // Reset to 0 each time a new code is issued.
    // Reaches 5 → current code is invalidated, user must request a new one.
    emailVerificationAttempts: {
      type: Number,
      default: 0,
    },
    // Password reset fields
    // Stores sha256 hash of the 6-digit OTP code (never the raw code).
    // Expires after 10 minutes — appropriate for short numeric OTPs.
    passwordResetCode: {
      type: String,
      default: null,
    },
    passwordResetExpires: {
      type: Date,
      default: null,
    },
    // Tracks consecutive failed code-entry attempts since last code generation.
    // Reset to 0 each time a new code is issued.
    // Reaches 5 → current code is invalidated, user must request a new one.
    passwordResetAttempts: {
      type: Number,
      default: 0,
    },
    // Refresh tokens for JWT authentication
    refreshTokens: {
      type: [String],
      default: [],
    },
    createdAt: {
      type: Date,
      default: Date.now,
    },
  },
  { timestamps: true }
);

// Hash password before saving
userSchema.pre('save', async function () {
  // Only hash if password was modified
  if (!this.isModified('password')) {
    return;
  }

  const salt = await bcrypt.genSalt(10);
  this.password = await bcrypt.hash(this.password, salt);
});

// Method to compare passwords
userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.password);
};

module.exports = mongoose.model('User', userSchema);