const QRCode = require('qrcode');

const generateGuichetQR = async (etablissementId, guichetId) => {
  const data = JSON.stringify({
    type: 'guichet',
    etablissementId,
    guichetId,
    generatedAt: new Date().toISOString(),
  });
  return await QRCode.toDataURL(data);
};

const generateTicketQR = async (ticketId, numero) => {
  const data = JSON.stringify({ type: 'ticket', ticketId, numero });
  return await QRCode.toDataURL(data);
};

module.exports = { generateGuichetQR, generateTicketQR };
