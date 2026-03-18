const crypto = require('crypto');

const generateOTP = () => {
  return crypto.randomInt(100000, 999999).toString();
};

const isOTPExpired = (expiresAt) => {
  return new Date() > new Date(expiresAt);
};

const canResendOTP = (lastSentAt, sendCount) => {
  if (sendCount >= 3) {
    const oneHourAgo = new Date(Date.now() - 3600000);
    if (new Date(lastSentAt) > oneHourAgo) return false;
  }
  return true;
};

module.exports = { generateOTP, isOTPExpired, canResendOTP };
