const User = require('../models/User');
const Etablissement = require('../models/Etablissement');
const Ticket = require('../models/Ticket');
const Service = require('../models/Service');
const Avis = require('../models/Avis');

// ============ STATS GLOBALES ============
exports.getStats = async (req, res) => {
  try {
    const totalUsers = await User.countDocuments();
    const usersActifs = await User.countDocuments({ statut: 'actif' });
    const usersSuspendus = await User.countDocuments({ statut: 'suspendu' });

    const totalEtablissements = await Etablissement.countDocuments();
    const etabActifs = await Etablissement.countDocuments({ statut: 'actif' });
    const etabEnAttente = await Etablissement.countDocuments({ statut: 'en_attente' });
    const etabSuspendus = await Etablissement.countDocuments({ statut: 'suspendu' });

    const totalTickets = await Ticket.countDocuments();

    // Tickets aujourd'hui
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    const ticketsAujourdHui = await Ticket.countDocuments({ createdAt: { $gte: today } });

    // Tickets cette semaine
    const weekStart = new Date();
    weekStart.setDate(weekStart.getDate() - weekStart.getDay());
    weekStart.setHours(0, 0, 0, 0);
    const ticketsSemaine = await Ticket.countDocuments({ createdAt: { $gte: weekStart } });

    // Tickets ce mois
    const monthStart = new Date();
    monthStart.setDate(1);
    monthStart.setHours(0, 0, 0, 0);
    const ticketsMois = await Ticket.countDocuments({ createdAt: { $gte: monthStart } });

    // Tickets par jour (7 derniers jours)
    const ticketsParJour = [];
    const jours = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam'];
    for (let i = 6; i >= 0; i--) {
      const date = new Date();
      date.setDate(date.getDate() - i);
      date.setHours(0, 0, 0, 0);
      const nextDate = new Date(date);
      nextDate.setDate(nextDate.getDate() + 1);
      const count = await Ticket.countDocuments({
        createdAt: { $gte: date, $lt: nextDate }
      });
      ticketsParJour.push({
        jour: jours[date.getDay()],
        date: date.toISOString().split('T')[0],
        tickets: count,
      });
    }

    // Top etablissements (par nombre de tickets)
    const topEtablissements = await Ticket.aggregate([
      { $group: { _id: '$etablissement', totalTickets: { $sum: 1 } } },
      { $sort: { totalTickets: -1 } },
      { $limit: 5 },
      { $lookup: { from: 'etablissements', localField: '_id', foreignField: '_id', as: 'etab' } },
      { $unwind: { path: '$etab', preserveNullAndEmptyArrays: true } },
      { $project: { nom: '$etab.nom', type: '$etab.type', totalTickets: 1 } },
    ]);

    // Adoption par ville
    const parVille = await Etablissement.aggregate([
      { $group: { _id: '$adresse.ville', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
      { $limit: 5 },
      { $project: { name: '$_id', value: '$count' } },
    ]);

    res.json({
      success: true,
      stats: {
        users: { total: totalUsers, actifs: usersActifs, suspendus: usersSuspendus },
        etablissements: { total: totalEtablissements, actifs: etabActifs, enAttente: etabEnAttente, suspendus: etabSuspendus },
        tickets: { total: totalTickets, aujourdHui: ticketsAujourdHui, semaine: ticketsSemaine, mois: ticketsMois },
        ticketsParJour,
        topEtablissements,
        parVille: parVille.length > 0 ? parVille : [{ name: 'Aucune donnee', value: 1 }],
      },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ============ LISTE ETABLISSEMENTS (ADMIN) ============
exports.getEtablissements = async (req, res) => {
  try {
    const { ville, type, statut, page = 1 } = req.query;
    const limit = 20;
    const skip = (page - 1) * limit;

    let query = {};
    if (ville) query['adresse.ville'] = new RegExp(ville, 'i');
    if (type) query.type = type;
    if (statut) query.statut = statut;

    const etablissements = await Etablissement.find(query)
      .populate('responsable', 'nom email telephone')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await Etablissement.countDocuments(query);

    res.json({
      success: true,
      etablissements,
      pagination: { page: parseInt(page), limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ============ CHANGER STATUT ETABLISSEMENT ============
exports.updateEtablissementStatut = async (req, res) => {
  try {
    const { id } = req.params;
    const { statut } = req.body;

    const etab = await Etablissement.findByIdAndUpdate(id, { statut }, { new: true });
    if (!etab) return res.status(404).json({ success: false, error: 'Etablissement non trouve' });

    res.json({ success: true, etablissement: etab });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ============ LISTE UTILISATEURS (ADMIN) ============
exports.getUsers = async (req, res) => {
  try {
    const { nom, telephone, email, role, statut, page = 1 } = req.query;
    const limit = 20;
    const skip = (page - 1) * limit;

    let query = {};
    if (nom) query.nom = new RegExp(nom, 'i');
    if (telephone) query.telephone = new RegExp(telephone, 'i');
    if (email) query.email = new RegExp(email, 'i');
    if (role) query.role = role;
    if (statut) query.statut = statut;

    const users = await User.find(query)
      .select('-motDePasse -otp -refreshTokens -resetPassword')
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit);

    const total = await User.countDocuments(query);

    res.json({
      success: true,
      users,
      pagination: { page: parseInt(page), limit, total, pages: Math.ceil(total / limit) },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ============ PROFIL UTILISATEUR (ADMIN) ============
exports.getUserById = async (req, res) => {
  try {
    const user = await User.findById(req.params.id)
      .select('-motDePasse -otp -refreshTokens -resetPassword');
    if (!user) return res.status(404).json({ success: false, error: 'Utilisateur non trouve' });

    // Historique tickets
    const tickets = await Ticket.find({ utilisateur: req.params.id })
      .populate('etablissement', 'nom')
      .populate('service', 'nom')
      .sort({ createdAt: -1 })
      .limit(50);

    res.json({ success: true, user, tickets });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ============ CHANGER STATUT UTILISATEUR ============
exports.updateUserStatut = async (req, res) => {
  try {
    const { id } = req.params;
    const { statut } = req.body;

    const user = await User.findByIdAndUpdate(id, { statut }, { new: true })
      .select('-motDePasse -otp -refreshTokens -resetPassword');
    if (!user) return res.status(404).json({ success: false, error: 'Utilisateur non trouve' });

    res.json({ success: true, user });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ============ SUPPRIMER UTILISATEUR ============
exports.deleteUser = async (req, res) => {
  try {
    const user = await User.findByIdAndDelete(req.params.id);
    if (!user) return res.status(404).json({ success: false, error: 'Utilisateur non trouve' });
    res.json({ success: true, message: 'Utilisateur supprime' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ============ CREER ETABLISSEMENT (ADMIN - valide directement) ============
exports.createEtablissement = async (req, res) => {
  try {
    const { nom, type, adresse, telephone, email, documents, responsableId } = req.body;

    const etablissement = new Etablissement({
      nom,
      type,
      adresse,
      telephone,
      email,
      responsable: responsableId || null,
      documents: documents || [],
      statut: 'actif',
    });

    await etablissement.save();

    console.log('[Admin] Etablissement cree et valide directement: ' + nom);

    res.status(201).json({
      success: true,
      message: 'Etablissement cree et valide. Visible par les clients.',
      etablissement,
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// ============ SUPPRIMER ETABLISSEMENT ============
exports.deleteEtablissement = async (req, res) => {
  try {
    const etab = await Etablissement.findByIdAndDelete(req.params.id);
    if (!etab) return res.status(404).json({ success: false, error: 'Etablissement non trouve' });
    // Supprimer services associes
    await Service.deleteMany({ etablissement: req.params.id });
    res.json({ success: true, message: 'Etablissement supprime' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
