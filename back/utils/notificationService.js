const { getMessaging } = require('./firebaseAdmin');
const User = require('../models/User');

/**
 * Send a push notification to a user's registered devices.
 * 
 * @param {String} userId - The MongoDB ID of the user
 * @param {Object} payload - Notification payload
 * @param {String} payload.title - Notification title
 * @param {String} payload.body - Notification body
 * @param {Object} payload.data - Optional data payload for custom handling
 */
const sendPushNotification = async (userId, { title, body, data = {} }) => {
  try {
    const user = await User.findById(userId).select('fcmTokens');
    
    if (!user || !user.fcmTokens || user.fcmTokens.length === 0) {
      console.log(`[Notification] No FCM tokens found for user ${userId}`);
      return;
    }

    const messaging = getMessaging();
    
    const message = {
      notification: {
        title,
        body
      },
      data: {
        ...data,
        click_action: 'FLUTTER_NOTIFICATION_CLICK'
      },
      tokens: user.fcmTokens,
    };

    const response = await messaging.sendEachForMulticast(message);
    
    // Check for failed tokens (expired, invalid, unregistered)
    if (response.failureCount > 0) {
      const failedTokens = [];
      response.responses.forEach((resp, idx) => {
        if (!resp.success) {
          const errorCode = resp.error?.code;
          if (
            errorCode === 'messaging/invalid-registration-token' ||
            errorCode === 'messaging/registration-token-not-registered' ||
            errorCode === 'messaging/mismatched-credential'
          ) {
            failedTokens.push(user.fcmTokens[idx]);
          }
        }
      });

      // Remove invalid tokens from the user's document
      if (failedTokens.length > 0) {
        await User.findByIdAndUpdate(userId, {
          $pullAll: { fcmTokens: failedTokens }
        });
        console.log(`[Notification] Removed ${failedTokens.length} invalid FCM tokens for user ${userId}`);
      }
    }

    console.log(`[Notification] Sent to user ${userId}. Success: ${response.successCount}, Failed: ${response.failureCount}`);
  } catch (error) {
    console.error(`[Notification] Error sending push notification to user ${userId}:`, error);
    // DO NOT throw error here, so we don't crash calling jobs or requests
  }
};

module.exports = {
  sendPushNotification,
};
