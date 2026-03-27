/**
 * WaQti - Service SMS
 * Supporte Twilio et Infobip (automatique selon les variables .env)
 *
 * --- TWILIO (https://console.twilio.com) ---
 * TWILIO_ACCOUNT_SID=ACxxx
 * TWILIO_AUTH_TOKEN=xxx
 * TWILIO_PHONE_NUMBER=+1xxx
 * ⚠️  Trial: SMS uniquement vers numéros vérifiés. Upgrade pour tous les numéros.
 *
 * --- INFOBIP (https://portal.infobip.com) - Meilleur pour +222 ---
 * INFOBIP_API_KEY=xxx
 * INFOBIP_BASE_URL=xxxxx.api.infobip.com
 * INFOBIP_SENDER=WaQti
 * Gratuit: 100 SMS/mois, fonctionne avec tous les numéros.
 */

const twilio = require('twilio');

let twilioClient = null;
let smsProvider = 'console'; // 'twilio' | 'infobip' | 'console'

const initTwilio = () => {
  // --- Infobip en priorité (meilleure couverture Mauritanie) ---
  const infobipKey = process.env.INFOBIP_API_KEY;
  const infobipBase = process.env.INFOBIP_BASE_URL;
  if (infobipKey && infobipBase && infobipKey !== 'your_infobip_key') {
    smsProvider = 'infobip';
    console.log('  [SMS] Infobip initialise - SMS actives');
    return;
  }

  // --- Twilio fallback ---
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;
  if (sid && token && sid !== 'your_sid' && sid.startsWith('AC')) {
    try {
      twilioClient = twilio(sid, token);
      smsProvider = 'twilio';
      console.log('  [SMS] Twilio initialise - SMS actives');
      console.log('  [SMS] ⚠️  Trial Twilio = SMS uniquement vers numeros verifies.');
      console.log('  [SMS]    Pour tous les numeros: upgrade sur console.twilio.com');
    } catch (err) {
      console.error('  [SMS] Erreur Twilio init:', err.message);
      smsProvider = 'console';
    }
    return;
  }

  console.log('  [SMS] Aucun provider configure - OTP visible en console uniquement');
  smsProvider = 'console';
};

const _sendViaInfobip = async (to, message) => {
  const https = require('node:https');
  const payload = JSON.stringify({
    messages: [{
      destinations: [{ to }],
      from: process.env.INFOBIP_SENDER || 'WaQti',
      text: message,
    }],
  });

  return new Promise((resolve, reject) => {
    const options = {
      hostname: process.env.INFOBIP_BASE_URL,
      path: '/sms/2/text/advanced',
      method: 'POST',
      headers: {
        'Authorization': 'App ' + process.env.INFOBIP_API_KEY,
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    };

    const req = https.request(options, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => {
        const result = JSON.parse(data);
        const status = result.messages?.[0]?.status?.groupName;
        if (status === 'PENDING' || status === 'DELIVERED') {
          console.log('[SMS] Infobip envoye a ' + to);
          resolve(result);
        } else {
          console.error('[SMS] Infobip erreur:', data);
          resolve(null);
        }
      });
    });

    req.on('error', (err) => {
      console.error('[SMS] Infobip request error:', err.message);
      reject(err);
    });

    req.write(payload);
    req.end();
  });
};

const sendSMS = async (to, message) => {
  if (smsProvider === 'infobip') {
    try {
      return await _sendViaInfobip(to, message);
    } catch (err) {
      console.error('[SMS] Infobip echec:', err.message);
      console.log('[SMS Console] -> ' + to + ': ' + message);
      return null;
    }
  }

  if (smsProvider === 'twilio') {
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
        console.log('[SMS] ⚠️  Numero non verifie sur Twilio Trial. Upgrade votre compte.');
      }
      console.log('[SMS Console] -> ' + to + ': ' + message);
      return null;
    }
  }

  // Console only
  console.log('[SMS Console] -> ' + to + ': ' + message);
  return null;
};

const sendOTP = async (telephone, otpCode) => {
  const message = 'WaQti: Votre code est ' + otpCode + '. Expire dans 5 min.\n' +
                  'رمزك: ' + otpCode + ' - WaQti';
  return sendSMS(telephone, message);
};

const sendResetLink = async (telephone, resetToken) => {
  const message = 'WaQti: Code de reinitialisation: ' + resetToken.substring(0, 8).toUpperCase();
  return sendSMS(telephone, message);
};

module.exports = { initTwilio, sendSMS, sendOTP, sendResetLink };
