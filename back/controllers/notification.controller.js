const User = require('../models/User');

// @desc    Register a new FCM token
// @route   POST /api/notifications/register-token
// @access  Private
exports.registerFcmToken = async (req, res, next) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'FCM token is required',
      });
    }

    const user = await User.findById(req.user.id);
    if (!user) {
      return res.status(404).json({
        success: false,
        error: 'User not found',
      });
    }

    // Add token if it doesn't already exist
    if (!user.fcmTokens.includes(token)) {
      user.fcmTokens.push(token);
      await user.save();
    }

    res.status(200).json({
      success: true,
      message: 'FCM token registered successfully',
    });
  } catch (error) {
    console.error('Error registering FCM token:', error);
    res.status(500).json({
      success: false,
      error: 'Server error registering FCM token',
    });
  }
};

// @desc    Unregister an FCM token
// @route   POST /api/notifications/unregister-token
// @access  Private
exports.unregisterFcmToken = async (req, res, next) => {
  try {
    const { token } = req.body;

    if (!token) {
      return res.status(400).json({
        success: false,
        error: 'FCM token is required',
      });
    }

    await User.findByIdAndUpdate(req.user.id, {
      $pull: { fcmTokens: token }
    });

    res.status(200).json({
      success: true,
      message: 'FCM token unregistered successfully',
    });
  } catch (error) {
    console.error('Error unregistering FCM token:', error);
    res.status(500).json({
      success: false,
      error: 'Server error unregistering FCM token',
    });
  }
};
