const mongoose = require('mongoose');

const serviceSchema = new mongoose.Schema({
  nom: { type: String, required: true, trim: true },
  description: { type: String, default: '' },
  etablissement: { type: mongoose.Schema.Types.ObjectId, ref: 'Etablissement', required: true },
  dureeEstimee: { type: Number, default: 10 },
  actif: { type: Boolean, default: true },

  guichets: [{
    numero: { type: Number, required: true },
    agent: { type: mongoose.Schema.Types.ObjectId, ref: 'Agent' },
    statut: { type: String, enum: ['ouvert', 'ferme', 'pause'], default: 'ferme' },
  }],
}, { timestamps: true });

serviceSchema.index({ etablissement: 1 });

module.exports = mongoose.model('Service', serviceSchema);
