const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Etablissement = require('../models/Etablissement');
const { accessTokenSecret, refreshTokenSecret, accessTokenExpiry, refreshTokenExpiry } = require('../config/jwt');
const { generateOTP, isOTPExpired } = require('../utils/otp');
const { ROLES, USER_STATUS } = require('../utils/constants');
const { sendOTP, sendResetLink } = require('../utils/sms');

// POST /api/auth/register
exports.register = async (req, res) => {
  try {
    const { nom, email, telephone, motDePasse } = req.body;

    const existing = await User.findOne({ $or: [{ email }, { telephone }] });
    if (existing) {
      return res.status(400).json({
        success: false,
        error: existing.email === email ? 'Email deja utilise' : 'Telephone deja utilise',
      });
    }

    const user = new User({ nom, email, telephone, motDePasse, role: ROLES.CLIENT });

    const otpCode = generateOTP();
    user.otp = {
      code: otpCode,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      attempts: 0,
      lastSentAt: new Date(),
      sendCount: 1,
    };

    await user.save();

    // TODO: Envoyer SMS via Twilio
    console.log('[OTP] ' + telephone + ': ' + otpCode);
    await sendOTP(telephone, otpCode);

    res.status(201).json({
      success: true,
      message: 'Compte cree. Verifiez votre telephone pour le code OTP.',
      userId: user._id,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/auth/login
exports.login = async (req, res) => {
  try {
    const { identifier, motDePasse } = req.body;

    const user = await User.findOne({
      $or: [{ email: identifier }, { telephone: identifier }],
    });

    if (!user || !(await user.comparePassword(motDePasse))) {
      return res.status(401).json({ success: false, error: 'Identifiants incorrects' });
    }

    if (user.statut === 'suspendu') {
      return res.status(403).json({ success: false, error: 'Compte suspendu' });
    }

    const otpCode = generateOTP();
    user.otp = {
      code: otpCode,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      attempts: 0,
      lastSentAt: new Date(),
      sendCount: (user.otp?.sendCount || 0) + 1,
    };
    await user.save();

    console.log('[OTP] ' + user.telephone + ': ' + otpCode);
    await sendOTP(user.telephone, otpCode);

    res.json({
      success: true,
      message: 'Code OTP envoye',
      userId: user._id,
      requiresOTP: true,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/auth/verify-otp
exports.verifyOTP = async (req, res) => {
  try {
    const { userId, code } = req.body;

    const user = await User.findById(userId);
    if (!user) return res.status(404).json({ success: false, error: 'Utilisateur non trouve' });

    if (user.otp.attempts >= 3) {
      return res.status(429).json({ success: false, error: 'Trop de tentatives. Demandez un nouveau code.' });
    }

    if (isOTPExpired(user.otp.expiresAt)) {
      return res.status(400).json({ success: false, error: 'Code OTP expire' });
    }

    if (user.otp.code !== code) {
      user.otp.attempts += 1;
      await user.save();
      return res.status(400).json({
        success: false,
        error: 'Code incorrect',
        attemptsLeft: 3 - user.otp.attempts,
      });
    }

    if (user.statut === USER_STATUS.UNVERIFIED) {
      user.statut = USER_STATUS.ACTIVE;
    }

    const accessToken = jwt.sign(
      { userId: user._id, role: user.role },
      accessTokenSecret,
      { expiresIn: accessTokenExpiry }
    );
    const refreshToken = jwt.sign(
      { userId: user._id },
      refreshTokenSecret,
      { expiresIn: refreshTokenExpiry }
    );

    user.refreshTokens.push({
      token: refreshToken,
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000),
    });

    user.otp = { code: null, expiresAt: null, attempts: 0, lastSentAt: null, sendCount: 0 };
    await user.save();

    res.json({
      success: true,
      message: 'Connexion reussie',
      accessToken,
      refreshToken,
      user: user.toJSON(),
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/auth/refresh-token
exports.refreshToken = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ success: false, error: 'Refresh token requis' });

    const decoded = jwt.verify(refreshToken, refreshTokenSecret);
    const user = await User.findById(decoded.userId);

    if (!user) return res.status(404).json({ success: false, error: 'Utilisateur non trouve' });

    const tokenExists = user.refreshTokens.find(t => t.token === refreshToken);
    if (!tokenExists) return res.status(401).json({ success: false, error: 'Token invalide' });

    const newAccessToken = jwt.sign(
      { userId: user._id, role: user.role },
      accessTokenSecret,
      { expiresIn: accessTokenExpiry }
    );

    res.json({ success: true, accessToken: newAccessToken });
  } catch (error) {
    res.status(401).json({ success: false, error: 'Token invalide ou expire' });
  }
};

// POST /api/auth/logout
exports.logout = async (req, res) => {
  try {
    const { refreshToken } = req.body;
    req.user.refreshTokens = req.user.refreshTokens.filter(t => t.token !== refreshToken);
    req.user.fcmToken = null;
    await req.user.save();
    res.json({ success: true, message: 'Deconnexion reussie' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// GET /api/auth/profile
exports.getProfile = async (req, res) => {
  res.json({ success: true, user: req.user.toJSON() });
};

// PUT /api/auth/profile
exports.updateProfile = async (req, res) => {
  try {
    const { nom, photo, nni } = req.body;
    if (nom) req.user.nom = nom;
    if (photo) req.user.photo = photo;
    if (nni) req.user.nni = nni;
    await req.user.save();
    res.json({ success: true, user: req.user.toJSON() });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/auth/change-phone
exports.changePhone = async (req, res) => {
  try {
    const { newPhone } = req.body;

    const existing = await User.findOne({ telephone: newPhone });
    if (existing) return res.status(400).json({ success: false, error: 'Numero deja utilise' });

    const otpCode = generateOTP();
    req.user.otp = {
      code: otpCode,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      attempts: 0,
      lastSentAt: new Date(),
      sendCount: 1,
    };
    await req.user.save();

    console.log('[OTP] Changement tel ' + newPhone + ': ' + otpCode);
    await sendOTP(newPhone, otpCode);
    res.json({ success: true, message: 'Code OTP envoye au nouveau numero' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/auth/forgot-password
exports.forgotPassword = async (req, res) => {
  try {
    const { telephone } = req.body;

    const user = await User.findOne({ telephone });
    if (!user) return res.status(404).json({ success: false, error: 'Utilisateur non trouve' });

    const resetToken = require('crypto').randomBytes(32).toString('hex');
    user.resetPassword = {
      token: resetToken,
      expiresAt: new Date(Date.now() + 15 * 60 * 1000),
    };
    await user.save();

    console.log('[Reset] ' + telephone + ': ' + resetToken);
    await sendResetLink(telephone, resetToken);
    res.json({ success: true, message: 'Lien de reinitialisation envoye par SMS' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/auth/reset-password
exports.resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    const user = await User.findOne({
      'resetPassword.token': token,
      'resetPassword.expiresAt': { $gt: new Date() },
    });

    if (!user) return res.status(400).json({ success: false, error: 'Token invalide ou expire' });

    user.motDePasse = newPassword;
    user.resetPassword = { token: null, expiresAt: null };
    user.refreshTokens = [];
    await user.save();

    res.json({ success: true, message: 'Mot de passe mis a jour' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/auth/register-etablissement
exports.registerEtablissement = async (req, res) => {
  try {
    const { nom, type, adresse, telephone, email, documents } = req.body;

    req.user.role = ROLES.MANAGER;
    await req.user.save();

    const etablissement = new Etablissement({
      nom,
      type,
      adresse,
      telephone,
      email,
      responsable: req.user._id,
      documents: documents || [],
    });

    await etablissement.save();

    console.log('[Admin] Nouvel etablissement en attente: ' + nom);

    res.status(201).json({
      success: true,
      message: 'Etablissement enregistre. En attente de validation.',
      etablissement,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
