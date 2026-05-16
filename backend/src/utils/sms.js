const twilio = require('twilio');
const { sendWhatsAppOTP, isWhatsAppConnected } = require('./whatsapp');

let twilioClient = null;

const initTwilio = () => {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  if (sid && token && sid.startsWith('AC')) {
    try {
      twilioClient = twilio(sid, token);
      console.log('  [SMS] Twilio initialise');
    } catch (err) {
      console.error('  [SMS] Erreur Twilio init:', err.message);
    }
    return;
  }
  console.log('  [SMS] Twilio non configure');
};

const sendSMSTwilio = async (to, message) => {
  if (!twilioClient) return null;
  try {
    const result = await twilioClient.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to,
    });
    console.log('[SMS] Twilio envoye a ' + to + ' (SID: ' + result.sid + ')');
    return result;
  } catch (err) {
    console.error('[SMS] Twilio echec:', err.message);
    if (err.code === 21608) {
      console.log('[SMS] Numero non verifie sur Twilio Trial');
    }
    return null;
  }
};

// Envoie OTP : WhatsApp en priorite, sinon Twilio, sinon console
const sendOTP = async (telephone, otpCode) => {
  // 1. WhatsApp (gratuit, illimite)
  if (isWhatsAppConnected()) {
    const sent = await sendWhatsAppOTP(telephone, otpCode);
    if (sent) return { method: 'whatsapp', success: true };
  }

  // 2. Twilio SMS (fallback)
  const message = 'WaQti: Votre code est ' + otpCode + '. Expire dans 5 min.';
  const result = await sendSMSTwilio(telephone, message);
  if (result) return { method: 'twilio', success: true };

  // 3. Console uniquement (dev)
  console.log('[OTP Console] ' + telephone + ' → ' + otpCode);
  return { method: 'console', success: false };
};

const sendResetLink = async (telephone, resetToken) => {
  const message = 'WaQti: Code de reinitialisation: ' + resetToken.substring(0, 8).toUpperCase();
  return sendSMSTwilio(telephone, message);
};

module.exports = { initTwilio, sendOTP, sendResetLink };
