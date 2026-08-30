const express = require('express');
const {
  registerFcmToken,
  unregisterFcmToken,
} = require('../controllers/notification.controller');
const { protect } = require('../middleware/authMiddleware');

const router = express.Router();

// Apply auth middleware to all notification routes
router.use(protect);

router.post('/register-token', registerFcmToken);
router.post('/unregister-token', unregisterFcmToken);

module.exports = router;
