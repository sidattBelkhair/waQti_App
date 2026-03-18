const mongoose = require('mongoose');

const fileSchema = new mongoose.Schema({
  service: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true, unique: true },
  etablissement: { type: mongoose.Schema.Types.ObjectId, ref: 'Etablissement', required: true },

  tickets: [{ type: mongoose.Schema.Types.ObjectId, ref: 'Ticket' }],
  ticketEnCours: { type: mongoose.Schema.Types.ObjectId, ref: 'Ticket', default: null },

  stats: {
    clientsTraites: { type: Number, default: 0 },
    tempsMoyenTraitement: { type: Number, default: 0 },
    tauxAbandon: { type: Number, default: 0 },
    derniereMAJ: { type: Date, default: Date.now },
  },

  dureeMoyenneParClient: { type: Number, default: 10 },
}, { timestamps: true });

module.exports = mongoose.model('File', fileSchema);
