const mongoose = require('mongoose');
const { ETAB_STATUS, ETAB_TYPES } = require('../utils/constants');

const etablissementSchema = new mongoose.Schema({
  nom: { type: String, required: true, trim: true },
  type: { type: String, enum: ETAB_TYPES, required: true },
  description: { type: String, default: '' },
  adresse: {
    rue: { type: String, required: true },
    ville: { type: String, required: true },
    codePostal: String,
    coordonnees: {
      type: { type: String, enum: ['Point'], default: 'Point' },
      coordinates: { type: [Number], default: [0, 0] },
    },
  },
  telephone: { type: String, required: true },
  email: String,
  photo: { type: String, default: null },
  responsable: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  documents: [{ nom: String, url: String, uploadedAt: Date }],
  statut: { type: String, enum: Object.values(ETAB_STATUS), default: ETAB_STATUS.PENDING },

  horaires: {
    lundi:    { ouvert: { type: Boolean, default: false }, debut: String, fin: String },
    mardi:    { ouvert: { type: Boolean, default: false }, debut: String, fin: String },
    mercredi: { ouvert: { type: Boolean, default: false }, debut: String, fin: String },
    jeudi:    { ouvert: { type: Boolean, default: false }, debut: String, fin: String },
    vendredi: { ouvert: { type: Boolean, default: false }, debut: String, fin: String },
    samedi:   { ouvert: { type: Boolean, default: false }, debut: String, fin: String },
    dimanche: { ouvert: { type: Boolean, default: false }, debut: String, fin: String },
  },

  fermetures: [{ date: Date, motif: String }],
  noteMoyenne: { type: Number, default: 0 },
  nombreAvis: { type: Number, default: 0 },

  abonnement: {
    type: { type: String, enum: ['gratuit', 'standard', 'premium'], default: 'gratuit' },
    expiresAt: Date,
  },
}, { timestamps: true });

etablissementSchema.index({ 'adresse.coordonnees': '2dsphere' });
etablissementSchema.index({ nom: 'text', description: 'text' });

module.exports = mongoose.model('Etablissement', etablissementSchema);
