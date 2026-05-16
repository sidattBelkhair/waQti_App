const mongoose = require('mongoose');

const WhatsappSessionSchema = new mongoose.Schema({
  _id: { type: String, default: 'main' },
  data: { type: Object, required: true },
}, { timestamps: true });

module.exports = mongoose.model('WhatsappSession', WhatsappSessionSchema);
