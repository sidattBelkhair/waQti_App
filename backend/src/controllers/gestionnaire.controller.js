const Ticket = require('../models/Ticket');
const Etablissement = require('../models/Etablissement');

// GET /api/gestionnaire/stats/today
exports.getStatsToday = async (req, res) => {
  try {
    const etab = await Etablissement.findOne({ responsable: req.user._id });
    if (!etab) return res.status(404).json({ success: false, error: 'Aucun etablissement' });

    const startOfDay = new Date();
    startOfDay.setHours(0, 0, 0, 0);

    const [servedTickets, absents, enAttente] = await Promise.all([
      Ticket.find({ etablissement: etab._id, statut: 'termine', finTraitement: { $gte: startOfDay } }),
      Ticket.countDocuments({ etablissement: etab._id, statut: 'absent', finTraitement: { $gte: startOfDay } }),
      Ticket.countDocuments({ etablissement: etab._id, statut: 'en_attente' }),
    ]);

    const durations = servedTickets
      .filter(t => t.debutTraitement && t.finTraitement)
      .map(t => (t.finTraitement - t.debutTraitement) / 60000);
    const tempsMoyenMinutes = durations.length > 0
      ? Math.round(durations.reduce((a, b) => a + b, 0) / durations.length)
      : 0;

    res.json({
      success: true,
      stats: {
        servis: servedTickets.length,
        enAttente,
        tempsMoyenMinutes,
        absents,
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
