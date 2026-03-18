const jwt = require('jsonwebtoken');
const { accessTokenSecret } = require('../config/jwt');
const User = require('../models/User');

const authenticateToken = async (req, res, next) => {
  try {
    const authHeader = req.headers.authorization;
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, error: 'Token manquant' });
    }

    const token = authHeader.split(' ')[1];
    const decoded = jwt.verify(token, accessTokenSecret);

    const user = await User.findById(decoded.userId);
    if (!user || user.statut === 'suspendu') {
      return res.status(401).json({ success: false, error: 'Non autorise' });
    }

    req.user = user;
    next();
  } catch (error) {
    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({ success: false, error: 'Token expire', code: 'TOKEN_EXPIRED' });
    }
    return res.status(401).json({ success: false, error: 'Token invalide' });
  }
};

const authorizeRoles = (...roles) => {
  return (req, res, next) => {
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({ success: false, error: 'Acces refuse pour ce role' });
    }
    next();
  };
};

module.exports = { authenticateToken, authorizeRoles };
