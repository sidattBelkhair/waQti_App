const router = require('express').Router();
const auth = require('../controllers/auth.controller');
const { authenticateToken } = require('../middleware/auth.middleware');
const { loginLimiter, otpLimiter, createAdminLimiter } = require('../middleware/rateLimiter');

// Routes publiques
router.post('/register', auth.register);
router.post('/login', loginLimiter, auth.login);
router.post('/verify-otp', otpLimiter, auth.verifyOTP);
router.post('/refresh-token', auth.refreshToken);
router.post('/forgot-password', auth.forgotPassword);
router.post('/reset-password', auth.resetPassword);
router.post('/create-admin', createAdminLimiter, auth.createAdmin);

// Routes protegees
router.post('/logout', authenticateToken, auth.logout);
router.get('/my-etablissement', authenticateToken, auth.getMyEtablissement);
router.get('/profile', authenticateToken, auth.getProfile);
router.put('/profile', authenticateToken, auth.updateProfile);
router.post('/change-phone', authenticateToken, auth.changePhone);
router.post('/register-etablissement', authenticateToken, auth.registerEtablissement);

module.exports = router;
