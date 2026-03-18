const mongoose = require('mongoose');

const agentSchema = new mongoose.Schema({
  nom: { type: String, required: true },
  role: { type: String, default: 'agent' },
  specialite: String,
  etablissement: { type: mongoose.Schema.Types.ObjectId, ref: 'Etablissement', required: true },

  disponibilites: {
    lundi:    { disponible: Boolean, debut: String, fin: String },
    mardi:    { disponible: Boolean, debut: String, fin: String },
    mercredi: { disponible: Boolean, debut: String, fin: String },
    jeudi:    { disponible: Boolean, debut: String, fin: String },
    vendredi: { disponible: Boolean, debut: String, fin: String },
    samedi:   { disponible: Boolean, debut: String, fin: String },
    dimanche: { disponible: Boolean, debut: String, fin: String },
  },

  conges: [{ debut: Date, fin: Date, motif: String }],
  statut: { type: String, enum: ['actif', 'en_conge', 'inactif'], default: 'actif' },
}, { timestamps: true });

module.exports = mongoose.model('Agent', agentSchema);
