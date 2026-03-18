const mongoose = require('mongoose');

const avisSchema = new mongoose.Schema({
  utilisateur: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  etablissement: { type: mongoose.Schema.Types.ObjectId, ref: 'Etablissement', required: true },
  note: { type: Number, required: true, min: 1, max: 5 },
  commentaire: { type: String, default: '' },
  ticket: { type: mongoose.Schema.Types.ObjectId, ref: 'Ticket' },
}, { timestamps: true });

avisSchema.index({ utilisateur: 1, ticket: 1 }, { unique: true });

module.exports = mongoose.model('Avis', avisSchema);
