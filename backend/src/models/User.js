const mongoose = require('mongoose');
const bcrypt = require('bcryptjs');
const { USER_STATUS, ROLES } = require('../utils/constants');

const userSchema = new mongoose.Schema({
  nom: {
    type: String,
    required: [true, 'Le nom est requis'],
    trim: true,
    minlength: 2,
  },
  email: {
    type: String,
    required: [true, 'L email est requis'],
    unique: true,
    lowercase: true,
    trim: true,
    match: [/^\S+@\S+\.\S+$/, 'Email invalide'],
  },
  telephone: {
    type: String,
    required: [true, 'Le telephone est requis'],
    unique: true,
    trim: true,
    match: [/^\+?[0-9]{8,15}$/, 'Telephone invalide'],
  },
  motDePasse: {
    type: String,
    required: [true, 'Le mot de passe est requis'],
    minlength: 6,
  },
  role: {
    type: String,
    enum: Object.values(ROLES),
    default: ROLES.CLIENT,
  },
  statut: {
    type: String,
    enum: Object.values(USER_STATUS),
    default: USER_STATUS.UNVERIFIED,
  },
  photo: { type: String, default: null },
  nni: { type: String, default: null },

  // OTP
  otp: {
    code: { type: String, default: null },
    expiresAt: { type: Date, default: null },
    attempts: { type: Number, default: 0 },
    lastSentAt: { type: Date, default: null },
    sendCount: { type: Number, default: 0 },
  },

  // Refresh Tokens
  refreshTokens: [{
    token: String,
    expiresAt: Date,
    createdAt: { type: Date, default: Date.now },
  }],

  // FCM Token (notifications push)
  fcmToken: { type: String, default: null },

  // Reinitialisation mot de passe
  resetPassword: {
    token: { type: String, default: null },
    expiresAt: { type: Date, default: null },
  },
}, {
  timestamps: true,
});

userSchema.pre('save', async function (next) {
  if (!this.isModified('motDePasse')) return next();
  this.motDePasse = await bcrypt.hash(this.motDePasse, 12);
  next();
});

userSchema.methods.comparePassword = async function (candidatePassword) {
  return await bcrypt.compare(candidatePassword, this.motDePasse);
};

userSchema.methods.toJSON = function () {
  const obj = this.toObject();
  delete obj.motDePasse;
  delete obj.otp;
  delete obj.refreshTokens;
  delete obj.resetPassword;
  return obj;
};

module.exports = mongoose.model('User', userSchema);
