const rateLimit = require('express-rate-limit');

const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 10,
  message: { success: false, error: 'Trop de tentatives, reessayez dans 15 minutes' },
  standardHeaders: true,
  legacyHeaders: false,
});

const otpLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  message: { success: false, error: 'Limite OTP atteinte, reessayez dans 1 heure' },
});

const apiLimiter = rateLimit({
  windowMs: 15 * 60 * 1000,
  max: 100,
  message: { success: false, error: 'Trop de requetes' },
});

// Max 3 tentatives de creation admin par heure par IP
const createAdminLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 3,
  message: { success: false, error: 'Trop de tentatives. Reessayez dans 1 heure.' },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = { loginLimiter, otpLimiter, apiLimiter, createAdminLimiter };
