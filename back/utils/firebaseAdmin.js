const admin = require('firebase-admin');

let isInitialized = false;

const getMessaging = () => {
  if (isInitialized) {
    return admin.messaging();
  }

  const base64ServiceAccount = process.env.FIREBASE_SERVICE_ACCOUNT_BASE64;

  if (!base64ServiceAccount) {
    console.warn('⚠️ FIREBASE_SERVICE_ACCOUNT_BASE64 is missing. Push notifications will be disabled.');
    // Return a dummy messaging object if disabled, to prevent crashes when testing locally
    return {
      sendEachForMulticast: async () => {
        console.log('[FCM Disabled] Would have sent multicast notification.');
        return { responses: [], successCount: 0, failureCount: 0 };
      },
    };
  }

  try {
    const serviceAccountJson = Buffer.from(base64ServiceAccount, 'base64').toString('utf-8');
    const serviceAccount = JSON.parse(serviceAccountJson);

    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount),
    });

    isInitialized = true;
    console.log('✅ Firebase Admin initialized successfully.');
    return admin.messaging();
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin:', error);
    // Return dummy to prevent crash on failure
    return {
      sendEachForMulticast: async () => {
        console.log('[FCM Error] Multicast skipped due to init error.');
        return { responses: [], successCount: 0, failureCount: 0 };
      },
    };
  }
};

module.exports = {
  getMessaging,
};
