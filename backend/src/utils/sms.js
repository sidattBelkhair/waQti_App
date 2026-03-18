/**
 * WaQti - Service d'envoi SMS via Twilio
 * 
 * Fichier : backend/src/utils/sms.js
 * 
 * CONFIGURATION :
 * 1. Allez sur https://www.twilio.com/try-twilio (compte gratuit)
 * 2. Verifiez votre numero de telephone
 * 3. Allez dans Console -> Account Info pour trouver :
 *    - Account SID
 *    - Auth Token
 * 4. Allez dans Phone Numbers -> Manage -> Buy a number
 *    (avec le credit gratuit de $15.50)
 * 5. Copiez ces 3 valeurs dans votre fichier .env
 * 
 * DANS .env :
 *   TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 *   TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
 *   TWILIO_PHONE_NUMBER=+1xxxxxxxxxx
 */

const twilio = require('twilio');

let client = null;

const initTwilio = () => {
  const sid = process.env.TWILIO_ACCOUNT_SID;
  const token = process.env.TWILIO_AUTH_TOKEN;

  if (!sid || !token || sid === 'your_sid') {
    console.log('  [SMS] Twilio non configure - OTP affiche en console uniquement');
    return null;
  }

  try {
    client = twilio(sid, token);
    console.log('  [SMS] Twilio initialise - SMS actives');
    return client;
  } catch (error) {
    console.error('  [SMS] Erreur Twilio:', error.message);
    return null;
  }
};

/**
 * Envoyer un SMS
 * @param {string} to - Numero de telephone (+222XXXXXXXX)
 * @param {string} message - Contenu du SMS
 * @returns {Promise<object|null>} - Resultat Twilio ou null si pas configure
 */
const sendSMS = async (to, message) => {
  // Si Twilio n'est pas configure, afficher en console
  if (!client) {
    console.log('[SMS Console] -> ' + to + ': ' + message);
    return null;
  }

  try {
    const result = await client.messages.create({
      body: message,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: to,
    });
    console.log('[SMS] Envoye a ' + to + ' (SID: ' + result.sid + ')');
    return result;
  } catch (error) {
    console.error('[SMS] Erreur envoi a ' + to + ':', error.message);
    // Fallback: afficher en console
    console.log('[SMS Fallback] -> ' + to + ': ' + message);
    return null;
  }
};

/**
 * Envoyer un OTP par SMS
 * @param {string} telephone - Numero du destinataire
 * @param {string} otpCode - Code OTP a 6 chiffres
 */
const sendOTP = async (telephone, otpCode) => {
  const messageFR = 'WaQti: Votre code de verification est ' + otpCode + '. Il expire dans 5 minutes.';
  const messageAR = 'WaQti: رمز التحقق الخاص بك هو ' + otpCode + '. ينتهي في 5 دقائق.';

  // Envoyer en francais et arabe
  const fullMessage = messageFR + '\n' + messageAR;

  return await sendSMS(telephone, fullMessage);
};

/**
 * Envoyer un lien de reinitialisation de mot de passe
 * @param {string} telephone - Numero du destinataire
 * @param {string} resetToken - Token de reinitialisation
 */
const sendResetLink = async (telephone, resetToken) => {
  const message = 'WaQti: Pour reinitialiser votre mot de passe, utilisez ce code: ' + resetToken.substring(0, 8).toUpperCase();
  return await sendSMS(telephone, message);
};

module.exports = { initTwilio, sendSMS, sendOTP, sendResetLink };