const { sendWhatsAppOTP, isWhatsAppConnected } = require('./whatsapp');

const sendOTP = async (telephone, otpCode) => {
  if (isWhatsAppConnected()) {
    const sent = await sendWhatsAppOTP(telephone, otpCode);
    if (sent) return { method: 'whatsapp', success: true };
  }
  console.log('[OTP Console] ' + telephone + ' -> ' + otpCode);
  return { method: 'console', success: false };
};

const sendResetLink = async (telephone, resetToken) => {
  const code = resetToken.substring(0, 8).toUpperCase();
  if (isWhatsAppConnected()) {
    await sendWhatsAppOTP(telephone, code);
  } else {
    console.log('[Reset] ' + telephone + ': ' + code);
  }
};

module.exports = { sendOTP, sendResetLink };
