const admin = require('firebase-admin');

let firebaseApp = null;

const initFirebase = () => {
  if (firebaseApp) return firebaseApp;
  try {
    firebaseApp = admin.initializeApp({
      credential: admin.credential.cert({
        projectId: process.env.FIREBASE_PROJECT_ID,
        privateKey: process.env.FIREBASE_PRIVATE_KEY?.replace(/\\n/g, '\n'),
        clientEmail: process.env.FIREBASE_CLIENT_EMAIL,
      }),
    });
    console.log('  Firebase Admin initialise');
  } catch (e) {
    console.warn('  Firebase non configure (notifications push desactivees)');
  }
  return firebaseApp;
};

const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!firebaseApp) return null;
  try {
    return await admin.messaging().send({
      token: fcmToken,
      notification: { title, body },
      data: Object.fromEntries(Object.entries(data).map(([k, v]) => [k, String(v)])),
      android: { priority: 'high' },
    });
  } catch (error) {
    console.error('[FCM] Erreur:', error.message);
    return null;
  }
};

module.exports = { initFirebase, sendPushNotification };
