const { default: makeWASocket, DisconnectReason, useMultiFileAuthState, fetchLatestBaileysVersion } = require('@whiskeysockets/baileys');
const pino = require('pino');
const qrcode = require('qrcode-terminal');
const path = require('path');

let sock = null;
let isConnected = false;

const SESSION_PATH = path.join(__dirname, '../../whatsapp_session');

const initWhatsApp = async () => {
  try {
    const { version } = await fetchLatestBaileysVersion();
    const { state, saveCreds } = await useMultiFileAuthState(SESSION_PATH);

    sock = makeWASocket({
      version,
      auth: state,
      printQRInTerminal: false,
      logger: pino({ level: 'silent' }),
      browser: ['WaQti', 'Chrome', '1.0.0'],
    });

    sock.ev.on('connection.update', (update) => {
      const { connection, lastDisconnect, qr } = update;

      if (qr) {
        console.log('\n\n  ============================================');
        console.log('  [WhatsApp] Scanne ce QR avec ton WhatsApp:');
        console.log('  ============================================\n');
        qrcode.generate(qr, { small: true });
        console.log('\n  ============================================\n');
      }

      if (connection === 'close') {
        isConnected = false;
        const code = lastDisconnect?.error?.output?.statusCode;
        const shouldReconnect = code !== DisconnectReason.loggedOut;
        if (shouldReconnect) {
          console.log('[WhatsApp] Reconnexion en cours...');
          setTimeout(initWhatsApp, 5000);
        } else {
          console.log('[WhatsApp] Session expiree - supprime whatsapp_session/ et redémarre');
        }
      } else if (connection === 'open') {
        isConnected = true;
        console.log('\n  [WhatsApp] ✓ Connecte ! OTP envoyes via WhatsApp\n');
      }
    });

    sock.ev.on('creds.update', saveCreds);
  } catch (err) {
    console.error('[WhatsApp] Erreur init:', err.message);
    setTimeout(initWhatsApp, 10000);
  }
};

const sendWhatsAppOTP = async (telephone, otpCode) => {
  if (!sock || !isConnected) return false;
  try {
    const jid = telephone.replace(/\D/g, '') + '@s.whatsapp.net';
    const message = `🕐 *WaQti*\n\nVotre code de vérification : *${otpCode}*\n\nExpire dans 5 minutes.`;
    await sock.sendMessage(jid, { text: message });
    console.log('[WhatsApp] OTP envoye a ' + telephone);
    return true;
  } catch (err) {
    console.error('[WhatsApp] Echec envoi a ' + telephone + ':', err.message);
    return false;
  }
};

const isWhatsAppConnected = () => isConnected;

module.exports = { initWhatsApp, sendWhatsAppOTP, isWhatsAppConnected };
