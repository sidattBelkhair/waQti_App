const mongoose = require('mongoose');
const { TICKET_STATUS, TICKET_MODE, PRIORITY } = require('../utils/constants');

const ticketSchema = new mongoose.Schema({
  numero: { type: String, required: true, unique: true },
  utilisateur: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true },
  etablissement: { type: mongoose.Schema.Types.ObjectId, ref: 'Etablissement', required: true },
  service: { type: mongoose.Schema.Types.ObjectId, ref: 'Service', required: true },

  mode: { type: String, enum: Object.values(TICKET_MODE), default: TICKET_MODE.DISTANCE },
  statut: { type: String, enum: Object.values(TICKET_STATUS), default: TICKET_STATUS.WAITING },
  priorite: { type: Number, enum: Object.values(PRIORITY), default: PRIORITY.NORMAL },

  position: { type: Number, default: 0 },
  tempsEstime: { type: Number, default: 0 },

  rdv: { date: Date, creneau: String },
  guichet: {
    numero: Number,
    agent: { type: mongoose.Schema.Types.ObjectId, ref: 'Agent' },
  },

  appelAt: Date,
  debutTraitement: Date,
  finTraitement: Date,

  retardSignale: { type: Boolean, default: false },
  retardAt: Date,
  qrCode: { type: String },
}, { timestamps: true });

ticketSchema.index({ etablissement: 1, service: 1, statut: 1 });
ticketSchema.index({ utilisateur: 1, createdAt: -1 });

module.exports = mongoose.model('Ticket', ticketSchema);
