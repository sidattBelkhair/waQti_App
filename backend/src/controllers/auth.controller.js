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
    const { nom, email, telephone, motDePasse, role } = req.body;

    const existingPhone = await User.findOne({ telephone });
    if (existingPhone) {
      return res.status(400).json({ success: false, error: 'Telephone deja utilise' });
    }
    if (email) {
      const existingEmail = await User.findOne({ email });
      if (existingEmail) {
        return res.status(400).json({ success: false, error: 'Email deja utilise' });
      }
    }

    const allowedRoles = [ROLES.CLIENT, ROLES.MANAGER];
    const userRole = allowedRoles.includes(role) ? role : ROLES.CLIENT;

    const user = new User({ nom, email, telephone, motDePasse, role: userRole });

    const otpCode = generateOTP();
    user.otp = {
      code: otpCode,
      expiresAt: new Date(Date.now() + 5 * 60 * 1000),
      attempts: 0,
      lastSentAt: new Date(),
      sendCount: 1,
    };

    await user.save();

    console.log('[OTP] ' + telephone + ': ' + otpCode);
    const smsSent = await sendOTP(telephone, otpCode);
    console.log('[OTP] SMS sent:', smsSent ? 'oui' : 'non (check Infobip logs)');

    res.status(201).json({
      success: true,
      message: 'Compte cree. Verifiez votre telephone pour le code OTP.',
      userId: user._id,
      devOtp: otpCode,
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

    if (user.statut === USER_STATUS.UNVERIFIED) {
      return res.status(403).json({
        success: false,
        error: 'Compte non verifie. Verifiez votre telephone d\'abord.',
        requiresVerification: true,
        userId: user._id,
      });
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

    const shortToken = resetToken.substring(0, 8).toUpperCase();
    console.log('[Reset] ' + telephone + ': ' + shortToken);
    await sendResetLink(telephone, resetToken);
    res.json({
      success: true,
      message: 'Code de réinitialisation envoyé par SMS',
      ...(process.env.NODE_ENV !== 'production' && { devToken: shortToken }),
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/auth/reset-password
exports.resetPassword = async (req, res) => {
  try {
    const { token, newPassword } = req.body;

    // Accepte le token complet OU les 8 premiers chars en majuscules (mode SMS)
    const user = await User.findOne({
      $or: [
        { 'resetPassword.token': token },
        { 'resetPassword.token': { $regex: new RegExp('^' + token, 'i') } },
      ],
      'resetPassword.expiresAt': { $gt: new Date() },
    });

    if (!user) return res.status(400).json({ success: false, error: 'Code invalide ou expiré' });

    user.motDePasse = newPassword;
    user.resetPassword = { token: null, expiresAt: null };
    user.refreshTokens = [];
    await user.save();

    res.json({ success: true, message: 'Mot de passe mis a jour' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/auth/create-admin (creation compte admin avec cle secrete)
exports.createAdmin = async (req, res) => {
  try {
    const { nom, telephone, motDePasse, secret } = req.body;

    // 1. Verifier la cle secrete (stockee uniquement en backend)
    const adminSecret = process.env.ADMIN_CREATE_SECRET;
    if (!adminSecret) {
      return res.status(500).json({ success: false, error: 'ADMIN_CREATE_SECRET non configure sur le serveur' });
    }
    if (!secret || secret !== adminSecret) {
      console.warn('[SECURITE] Tentative creation admin avec mauvaise cle - IP: ' + (req.ip || 'inconnue'));
      return res.status(403).json({ success: false, error: 'Cle secrete incorrecte' });
    }

    // 2. Limiter le nombre total d'admins (max 5)
    const adminCount = await User.countDocuments({ role: ROLES.ADMIN });
    if (adminCount >= 5) {
      return res.status(403).json({ success: false, error: 'Nombre maximum d\'administrateurs atteint' });
    }

    // 3. Verifier champs obligatoires
    if (!nom || !telephone || !motDePasse) {
      return res.status(400).json({ success: false, error: 'Nom, telephone et mot de passe requis' });
    }
    if (motDePasse.length < 8) {
      return res.status(400).json({ success: false, error: 'Mot de passe minimum 8 caracteres' });
    }

    // 4. Verifier unicite telephone
    const existing = await User.findOne({ telephone });
    if (existing) {
      return res.status(400).json({ success: false, error: 'Telephone deja utilise' });
    }

    const user = new User({
      nom,
      telephone,
      motDePasse,
      role: ROLES.ADMIN,
      statut: USER_STATUS.ACTIVE,
    });
    await user.save();

    console.log('[ADMIN] Nouveau compte admin cree: ' + telephone + ' (' + nom + ')');
    res.status(201).json({ success: true, message: 'Compte admin cree avec succes' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// GET /api/auth/my-etablissement
exports.getMyEtablissement = async (req, res) => {
  try {
    const etab = await Etablissement.findOne({ responsable: req.user._id });
    if (!etab) return res.status(404).json({ success: false, error: 'Aucun etablissement trouve' });
    res.json({ success: true, etablissement: etab });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/auth/register-etablissement (gestionnaire uniquement)
exports.registerEtablissement = async (req, res) => {
  try {
    if (req.user.role !== ROLES.MANAGER) {
      return res.status(403).json({
        success: false,
        error: 'Seuls les gestionnaires peuvent enregistrer un etablissement.',
      });
    }

    const { nom, type, adresse, telephone, email, documents } = req.body;

    const etablissement = new Etablissement({
      nom,
      type,
      adresse,
      telephone,
      email,
      responsable: req.user._id,
      documents: documents || [],
      statut: 'en_attente',
    });

    await etablissement.save();

    console.log('[Gestionnaire] Nouvel etablissement en attente de validation: ' + nom);

    res.status(201).json({
      success: true,
      message: 'Etablissement enregistre. En attente de validation par un administrateur.',
      etablissement,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
