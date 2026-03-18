const File = require('../models/File');
const Ticket = require('../models/Ticket');

// GET /api/files/:serviceId
exports.getFileStatus = async (req, res) => {
  try {
    const file = await File.findOne({ service: req.params.serviceId })
      .populate('tickets')
      .populate('ticketEnCours');

    if (!file) return res.status(404).json({ success: false, error: 'File non trouvee' });

    res.json({
      success: true,
      file: {
        totalEnAttente: file.tickets.length,
        ticketEnCours: file.ticketEnCours,
        tickets: file.tickets,
        stats: file.stats,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// GET /api/files/:serviceId/position
exports.getPosition = async (req, res) => {
  try {
    const ticket = await Ticket.findOne({
      service: req.params.serviceId,
      utilisateur: req.user._id,
      statut: 'en_attente',
    });

    if (!ticket) return res.status(404).json({ success: false, error: 'Aucun ticket actif' });

    res.json({
      success: true,
      position: ticket.position,
      tempsEstime: ticket.tempsEstime,
      numero: ticket.numero,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
