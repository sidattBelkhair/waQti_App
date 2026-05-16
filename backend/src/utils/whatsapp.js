const { default: makeWASocket, DisconnectReason, fetchLatestBaileysVersion, initAuthCreds, BufferJSON, proto } = require('@whiskeysockets/baileys');
const pino = require('pino');
const qrcode = require('qrcode-terminal');
const WhatsappSession = require('../models/WhatsappSession');

let sock = null;
let isConnected = false;

// Auth state stocké dans MongoDB
const useMongoAuthState = async () => {
  const loadSession = async () => {
    const doc = await WhatsappSession.findById('main');
    return doc ? doc.data : null;
  };

  const saveSession = async (data) => {
    await WhatsappSession.findByIdAndUpdate(
      'main',
      { data },
      { upsert: true, new: true }
    );
  };

  const sessionData = await loadSession();
  let creds = sessionData?.creds ? JSON.parse(JSON.stringify(sessionData.creds), BufferJSON.reviver) : initAuthCreds();
  let keys = sessionData?.keys || {};

  const saveCreds = async () => {
    await saveSession({
      creds: JSON.parse(JSON.stringify(creds, BufferJSON.replacer)),
      keys,
    });
  };

  return {
    state: {
      creds,
      keys: {
        get: async (type, ids) => {
          const data = {};
          for (const id of ids) {
            const val = keys[`${type}-${id}`];
            if (val) data[id] = JSON.parse(JSON.stringify(val, BufferJSON.reviver));
          }
          return data;
        },
        set: async (data) => {
          for (const [category, items] of Object.entries(data)) {
            for (const [id, val] of Object.entries(items)) {
              if (val) {
                keys[`${category}-${id}`] = val;
              } else {
                delete keys[`${category}-${id}`];
              }
            }
          }
          await saveCreds();
        },
      },
    },
    saveCreds,
  };
};

const initWhatsApp = async () => {
  try {
    const { version } = await fetchLatestBaileysVersion();
    const { state, saveCreds } = await useMongoAuthState();

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
        console.log('\n  ============================================');
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
          console.log('[WhatsApp] Reconnexion...');
          setTimeout(initWhatsApp, 5000);
        } else {
          console.log('[WhatsApp] Session expiree - scanne le QR a nouveau');
        }
      } else if (connection === 'open') {
        isConnected = true;
        console.log('  [WhatsApp] Connecte ! OTP envoyes via WhatsApp');
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
    console.error('[WhatsApp] Echec envoi:', err.message);
    return false;
  }
};

const isWhatsAppConnected = () => isConnected;

module.exports = { initWhatsApp, sendWhatsAppOTP, isWhatsAppConnected };
