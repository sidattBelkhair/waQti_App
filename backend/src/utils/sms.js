const twilio = require('twilio');

let twilioClient = null;

const initTwilio = () => {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  if (sid && token && sid.startsWith('AC')) {
    try {
      twilioClient = twilio(sid, token);
      console.log('  [SMS] Twilio initialise - SMS actives');
    } catch (err) {
      console.error('  [SMS] Erreur Twilio init:', err.message);
    }
    return;
  }
  console.log('  [SMS] Twilio non configure - OTP visible en console uniquement');
};

const sendSMS = async (to, message) => {
  if (twilioClient) {
    try {
      const result = await twilioClient.messages.create({
        body: message,
        from: process.env.TWILIO_PHONE_NUMBER,
        to,
      });
      console.log('[SMS] Twilio envoye a ' + to + ' (SID: ' + result.sid + ')');
      return result;
    } catch (err) {
      console.error('[SMS] Twilio echec a ' + to + ':', err.message);
      if (err.code === 21608) {
        console.log('[SMS] Numero non verifie sur Twilio Trial - verifie sur console.twilio.com');
      }
      return null;
    }
  }
  console.log('[SMS Console] -> ' + to + ': ' + message);
  return null;
};

const sendOTP = async (telephone, otpCode) => {
  const message = 'WaQti: Votre code est ' + otpCode + '. Expire dans 5 min.';
  return sendSMS(telephone, message);
};

const sendResetLink = async (telephone, resetToken) => {
  const message = 'WaQti: Code de reinitialisation: ' + resetToken.substring(0, 8).toUpperCase();
  return sendSMS(telephone, message);
};

module.exports = { initTwilio, sendSMS, sendOTP, sendResetLink };
