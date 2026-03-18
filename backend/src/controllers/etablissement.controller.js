const Etablissement = require('../models/Etablissement');
const Service = require('../models/Service');
const Agent = require('../models/Agent');
const Avis = require('../models/Avis');
const Ticket = require('../models/Ticket');

// GET /api/etablissements/:id
exports.getEtablissement = async (req, res) => {
  try {
    const etab = await Etablissement.findById(req.params.id).populate('responsable', 'nom email');
    if (!etab) return res.status(404).json({ success: false, error: 'Etablissement non trouve' });
    res.json({ success: true, etablissement: etab });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// PUT /api/etablissements/:id
exports.updateEtablissement = async (req, res) => {
  try {
    const { nom, description, adresse, telephone, photo, horaires } = req.body;
    const etab = await Etablissement.findById(req.params.id);
    if (!etab) return res.status(404).json({ success: false, error: 'Etablissement non trouve' });
    if (etab.responsable.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, error: 'Non autorise' });
    }
    if (nom) etab.nom = nom;
    if (description) etab.description = description;
    if (adresse) etab.adresse = adresse;
    if (telephone) etab.telephone = telephone;
    if (photo) etab.photo = photo;
    if (horaires) etab.horaires = horaires;
    await etab.save();
    res.json({ success: true, etablissement: etab });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/etablissements/:id/fermetures
exports.addFermeture = async (req, res) => {
  try {
    const etab = await Etablissement.findById(req.params.id);
    if (!etab) return res.status(404).json({ success: false, error: 'Etablissement non trouve' });
    etab.fermetures.push(req.body);
    await etab.save();
    res.json({ success: true, fermetures: etab.fermetures });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/etablissements/:id/services
exports.createService = async (req, res) => {
  try {
    const service = new Service({ ...req.body, etablissement: req.params.id });
    await service.save();
    res.status(201).json({ success: true, service });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// PUT /api/etablissements/:id/services/:serviceId
exports.updateService = async (req, res) => {
  try {
    const service = await Service.findByIdAndUpdate(req.params.serviceId, req.body, { new: true });
    if (!service) return res.status(404).json({ success: false, error: 'Service non trouve' });
    res.json({ success: true, service });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// DELETE /api/etablissements/:id/services/:serviceId
exports.deleteService = async (req, res) => {
  try {
    await Service.findByIdAndDelete(req.params.serviceId);
    res.json({ success: true, message: 'Service supprime' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// GET /api/etablissements/:id/services
exports.getServices = async (req, res) => {
  try {
    const services = await Service.find({ etablissement: req.params.id });
    res.json({ success: true, services });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/services/:serviceId/guichets
exports.addGuichet = async (req, res) => {
  try {
    const service = await Service.findById(req.params.serviceId);
    if (!service) return res.status(404).json({ success: false, error: 'Service non trouve' });
    service.guichets.push(req.body);
    await service.save();
    res.json({ success: true, guichets: service.guichets });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/etablissements/:id/personnel
exports.addAgent = async (req, res) => {
  try {
    const agent = new Agent({ ...req.body, etablissement: req.params.id });
    await agent.save();
    res.status(201).json({ success: true, agent });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// GET /api/etablissements/:id/personnel
exports.getPersonnel = async (req, res) => {
  try {
    const agents = await Agent.find({ etablissement: req.params.id });
    res.json({ success: true, agents });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// PUT /api/etablissements/:id/personnel/:agentId/disponibilites
exports.updateDisponibilites = async (req, res) => {
  try {
    const agent = await Agent.findByIdAndUpdate(req.params.agentId, { disponibilites: req.body }, { new: true });
    if (!agent) return res.status(404).json({ success: false, error: 'Agent non trouve' });
    res.json({ success: true, agent });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/etablissements/:id/personnel/:agentId/conges
exports.addConge = async (req, res) => {
  try {
    const agent = await Agent.findById(req.params.agentId);
    if (!agent) return res.status(404).json({ success: false, error: 'Agent non trouve' });
    agent.conges.push(req.body);
    agent.statut = 'en_conge';
    await agent.save();
    res.json({ success: true, agent });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// GET /api/etablissements (recherche)
exports.searchEtablissements = async (req, res) => {
  try {
    const { nom, type, ville, lat, lng, page = 1 } = req.query;
    const limit = 20;
    const skip = (page - 1) * limit;

    let query = { statut: 'actif' };
    if (nom) query.$text = { $search: nom };
    if (type) query.type = type;
    if (ville) query['adresse.ville'] = new RegExp(ville, 'i');

    let findQuery;

    if (lat && lng) {
      findQuery = Etablissement.find({
        ...query,
        'adresse.coordonnees': {
          $near: {
            $geometry: { type: 'Point', coordinates: [parseFloat(lng), parseFloat(lat)] },
            $maxDistance: 50000,
          },
        },
      });
    } else {
      findQuery = Etablissement.find(query);
    }

    const etablissements = await findQuery
      .select('nom type adresse.ville adresse.coordonnees noteMoyenne photo horaires')
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

// POST /api/etablissements/:id/avis
exports.createAvis = async (req, res) => {
  try {
    const { note, commentaire, ticketId } = req.body;
    const etabId = req.params.id;

    const ticket = await Ticket.findOne({
      _id: ticketId,
      utilisateur: req.user._id,
      etablissement: etabId,
      statut: 'termine',
    });

    if (!ticket) {
      return res.status(400).json({
        success: false,
        error: 'Vous devez avoir un ticket termine pour laisser un avis',
      });
    }

    const avis = new Avis({
      utilisateur: req.user._id,
      etablissement: etabId,
      note,
      commentaire,
      ticket: ticketId,
    });
    await avis.save();

    const allAvis = await Avis.find({ etablissement: etabId });
    const moyenne = allAvis.reduce((sum, a) => sum + a.note, 0) / allAvis.length;

    await Etablissement.findByIdAndUpdate(etabId, {
      noteMoyenne: Math.round(moyenne * 10) / 10,
      nombreAvis: allAvis.length,
    });

    res.status(201).json({ success: true, avis });
  } catch (error) {
    if (error.code === 11000) {
      return res.status(400).json({ success: false, error: 'Vous avez deja laisse un avis pour ce ticket' });
    }
    res.status(500).json({ success: false, error: error.message });
  }
};

// GET /api/etablissements/:id/avis
exports.getAvis = async (req, res) => {
  try {
    const { page = 1 } = req.query;
    const limit = 10;
    const avis = await Avis.find({ etablissement: req.params.id })
      .populate('utilisateur', 'nom photo')
      .sort({ createdAt: -1 })
      .skip((page - 1) * limit)
      .limit(limit);

    res.json({ success: true, avis });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
