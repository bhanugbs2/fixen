const admin = require('firebase-admin');
const fs = require('fs');
const path = require('path');

let firebaseApp = null;
let messaging = null;

try {
  const credentialsPath = process.env.FIREBASE_SERVICE_ACCOUNT_PATH;
  
  if (credentialsPath && fs.existsSync(credentialsPath)) {
    const serviceAccount = JSON.parse(fs.readFileSync(credentialsPath, 'utf8'));
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    messaging = admin.messaging();
    console.log('Firebase Admin SDK initialized successfully.');
  } else {
    console.log('Firebase credentials not found or empty path. Running Firebase in Mock/Stub mode.');
  }
} catch (error) {
  console.warn('Failed to initialize Firebase Admin SDK. Push notifications will run in mock mode. Error:', error.message);
}

// Function to send push notifications safely
const sendPushNotification = async (fcmToken, title, body, payload = {}) => {
  if (!fcmToken) return { success: false, message: 'Token missing' };

  const message = {
    notification: { title, body },
    data: {
      ...payload,
      click_action: 'FLUTTER_NOTIFICATION_CLICK'
    },
    token: fcmToken
  };

  try {
    if (messaging) {
      const response = await messaging.send(message);
      console.log('Successfully sent push notification:', response);
      return { success: true, response };
    } else {
      console.log(`[MOCK NOTIFICATION] Token: ${fcmToken} | Title: ${title} | Body: ${body} | Payload:`, payload);
      return { success: true, mock: true };
    }
  } catch (error) {
    console.error('Error sending push notification:', error.message);
    return { success: false, error: error.message };
  }
};

module.exports = {
  sendPushNotification
};
