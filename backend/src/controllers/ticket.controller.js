const Ticket = require('../models/Ticket');
const File = require('../models/File');
const { TICKET_STATUS, TICKET_MODE, PRIORITY, WS_EVENTS } = require('../utils/constants');

const generateTicketNumber = () => {
  const d = new Date();
  const prefix = 'WQ' + d.getFullYear().toString().slice(2) + String(d.getMonth() + 1).padStart(2, '0') + String(d.getDate()).padStart(2, '0');
  const random = Math.floor(Math.random() * 9999).toString().padStart(4, '0');
  return prefix + '-' + random;
};

async function recalculerPositions(fileId, io) {
  const file = await File.findById(fileId);
  if (!file) return;

  const ticketsSorted = await Ticket.find({ _id: { $in: file.tickets } })
    .sort({ priorite: 1, createdAt: 1 });

  for (let i = 0; i < ticketsSorted.length; i++) {
    ticketsSorted[i].position = i + 1;
    ticketsSorted[i].tempsEstime = (i + 1) * file.dureeMoyenneParClient;
    await ticketsSorted[i].save();

    io.to('user_' + ticketsSorted[i].utilisateur).emit(WS_EVENTS.FILE_UPDATED, {
      ticketId: ticketsSorted[i]._id,
      position: ticketsSorted[i].position,
      tempsEstime: ticketsSorted[i].tempsEstime,
    });
  }

  file.tickets = ticketsSorted.map(t => t._id);
  await file.save();
}

// GET /api/tickets/mes-tickets
exports.getMesTickets = async (req, res) => {
  try {
    const tickets = await Ticket.find({
      utilisateur: req.user._id,
      statut: { $in: ['en_attente', 'en_cours'] },
    })
      .populate('etablissement', 'nom type')
      .populate('service', 'nom')
      .sort({ createdAt: -1 });
    res.json({ success: true, tickets });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/tickets
exports.createTicket = async (req, res) => {
  try {
    const { etablissementId, serviceId, mode, priorite } = req.body;
    const io = req.app.get('io');

    let file = await File.findOne({ service: serviceId, etablissement: etablissementId });
    if (!file) {
      file = new File({ service: serviceId, etablissement: etablissementId });
      await file.save();
    }

    const position = file.tickets.length + 1;
    const tempsEstime = position * file.dureeMoyenneParClient;

    const ticket = new Ticket({
      numero: generateTicketNumber(),
      utilisateur: req.user._id,
      etablissement: etablissementId,
      service: serviceId,
      mode: mode || TICKET_MODE.DISTANCE,
      priorite: priorite || PRIORITY.NORMAL,
      position,
      tempsEstime,
    });

    await ticket.save();
    file.tickets.push(ticket._id);
    await file.save();
    await recalculerPositions(file._id, io);

    io.to('service_' + serviceId).emit(WS_EVENTS.FILE_UPDATED, {
      serviceId,
      totalEnAttente: file.tickets.length,
    });

    const populated = await Ticket.findById(ticket._id)
      .populate('service')
      .populate('etablissement', 'nom');

    res.status(201).json({ success: true, ticket: populated });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/tickets/rdv
exports.createTicketRDV = async (req, res) => {
  try {
    const { etablissementId, serviceId, date, creneau } = req.body;

    const ticket = new Ticket({
      numero: generateTicketNumber(),
      utilisateur: req.user._id,
      etablissement: etablissementId,
      service: serviceId,
      mode: TICKET_MODE.APPOINTMENT,
      rdv: { date: new Date(date), creneau },
    });

    await ticket.save();
    res.status(201).json({ success: true, ticket });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// DELETE /api/tickets/:id/annuler
exports.cancelTicket = async (req, res) => {
  try {
    const { id } = req.params;
    const io = req.app.get('io');

    const ticket = await Ticket.findById(id);
    if (!ticket) return res.status(404).json({ success: false, error: 'Ticket non trouve' });
    if (ticket.utilisateur.toString() !== req.user._id.toString()) {
      return res.status(403).json({ success: false, error: 'Non autorise' });
    }

    ticket.statut = TICKET_STATUS.CANCELLED;
    await ticket.save();

    const file = await File.findOne({ service: ticket.service });
    if (file) {
      file.tickets = file.tickets.filter(t => t.toString() !== id);
      await file.save();
      await recalculerPositions(file._id, io);
    }

    io.to('service_' + ticket.service).emit(WS_EVENTS.TICKET_CANCELLED, { ticketId: id });
    res.json({ success: true, message: 'Ticket annule' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/tickets/:id/signaler-retard
exports.signalRetard = async (req, res) => {
  try {
    const ticket = await Ticket.findById(req.params.id);
    if (!ticket) return res.status(404).json({ success: false, error: 'Ticket non trouve' });

    ticket.retardSignale = true;
    ticket.retardAt = new Date();
    await ticket.save();

    res.json({ success: true, message: 'Retard signale, votre place est conservee' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/tickets/:id/valider-presence
exports.validerPresence = async (req, res) => {
  try {
    const { id } = req.params;
    const io = req.app.get('io');

    const ticket = await Ticket.findById(id).populate('utilisateur', 'nom telephone');
    if (!ticket) return res.status(404).json({ success: false, error: 'Ticket non trouve' });

    const file = await File.findOne({ service: ticket.service });

    if (file && file.ticketEnCours) {
      const precedent = await Ticket.findById(file.ticketEnCours);
      if (precedent) {
        precedent.statut = TICKET_STATUS.COMPLETED;
        precedent.finTraitement = new Date();
        await precedent.save();
        file.stats.clientsTraites += 1;
      }
    }

    ticket.statut = TICKET_STATUS.IN_PROGRESS;
    ticket.debutTraitement = new Date();
    await ticket.save();

    if (file) {
      file.ticketEnCours = ticket._id;
      file.tickets = file.tickets.filter(t => t.toString() !== id);
      await file.save();
      await recalculerPositions(file._id, io);
    }

    res.json({
      success: true,
      message: 'Presence validee',
      client: { nom: ticket.utilisateur.nom, numero: ticket.numero },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/tickets/scan/:numero/valider — valider présence par numéro de ticket (QR simple)
exports.validerPresenceByNumero = async (req, res) => {
  try {
    const { numero } = req.params;
    const io = req.app.get('io');

    const ticket = await Ticket.findOne({ numero: numero.toUpperCase() })
      .populate('utilisateur', 'nom telephone');
    if (!ticket) return res.status(404).json({ success: false, error: 'Ticket non trouvé' });
    if (ticket.statut !== TICKET_STATUS.WAITING) {
      return res.status(400).json({ success: false, error: 'Ticket déjà traité ou annulé' });
    }

    const file = await File.findOne({ service: ticket.service });

    if (file && file.ticketEnCours) {
      const precedent = await Ticket.findById(file.ticketEnCours);
      if (precedent) {
        precedent.statut = TICKET_STATUS.COMPLETED;
        precedent.finTraitement = new Date();
        await precedent.save();
        file.stats.clientsTraites += 1;
      }
    }

    ticket.statut = TICKET_STATUS.IN_PROGRESS;
    ticket.debutTraitement = new Date();
    await ticket.save();

    if (file) {
      file.ticketEnCours = ticket._id;
      file.tickets = file.tickets.filter(t => t.toString() !== ticket._id.toString());
      await file.save();
      await recalculerPositions(file._id, io);
    }

    res.json({
      success: true,
      message: 'Présence validée',
      client: { nom: ticket.utilisateur.nom, numero: ticket.numero },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// POST /api/files/:serviceId/appeler-suivant
exports.appelSuivant = async (req, res) => {
  try {
    const { serviceId } = req.params;
    const io = req.app.get('io');

    const file = await File.findOne({ service: serviceId }).populate({
      path: 'tickets',
      populate: { path: 'utilisateur', select: 'nom telephone fcmToken' },
    });

    if (!file || file.tickets.length === 0) {
      return res.status(404).json({ success: false, error: 'File vide' });
    }

    if (file.ticketEnCours) {
      const precedent = await Ticket.findById(file.ticketEnCours);
      if (precedent && precedent.statut === TICKET_STATUS.IN_PROGRESS) {
        precedent.statut = TICKET_STATUS.COMPLETED;
        precedent.finTraitement = new Date();
        await precedent.save();
        file.stats.clientsTraites += 1;
      }
    }

    const prochainId = file.tickets[0];
    const prochain = await Ticket.findById(prochainId).populate('utilisateur', 'nom telephone fcmToken');

    prochain.statut = TICKET_STATUS.IN_PROGRESS;
    prochain.appelAt = new Date();
    await prochain.save();

    file.ticketEnCours = prochainId;
    file.tickets.shift();
    await file.save();

    io.to('user_' + prochain.utilisateur._id).emit(WS_EVENTS.YOUR_TURN, {
      ticketId: prochain._id,
      numero: prochain.numero,
      guichet: req.body.guichet || 1,
    });

    if (file.tickets.length > 0) {
      const deuxieme = await Ticket.findById(file.tickets[0]);
      if (deuxieme) {
        io.to('user_' + deuxieme.utilisateur).emit(WS_EVENTS.YOUR_TURN_APPROACHING, {
          ticketId: deuxieme._id,
          position: 1,
        });
      }
    }

    await recalculerPositions(file._id, io);

    // TODO: Envoyer notification push FCM

    res.json({
      success: true,
      message: 'Client suivant appele',
      client: { nom: prochain.utilisateur.nom, numero: prochain.numero },
    });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

// GET /api/tickets/etablissement — tickets de l'etablissement du gestionnaire
exports.getEtablissementTickets = async (req, res) => {
  try {
    const Etablissement = require('../models/Etablissement');
    const etab = await Etablissement.findOne({ responsable: req.user._id });
    if (!etab) return res.status(404).json({ success: false, error: 'Aucun etablissement' });

    const tickets = await Ticket.find({
      etablissement: etab._id,
      statut: { $in: ['en_cours', 'termine', 'absent'] },
    })
      .populate('utilisateur', 'nom telephone')
      .populate('service', 'nom')
      .sort({ updatedAt: -1 })
      .limit(100);

    res.json({ success: true, tickets });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};

exports.marquerAbsent = async (req, res) => {
  try {
    const { serviceId } = req.params;
    const io = req.app.get('io');

    const file = await File.findOne({ service: serviceId });
    if (!file || !file.ticketEnCours) {
      return res.status(404).json({ success: false, error: 'Aucun ticket en cours' });
    }

    const ticket = await Ticket.findById(file.ticketEnCours);
    if (!ticket) {
      return res.status(404).json({ success: false, error: 'Ticket introuvable' });
    }

    ticket.statut = 'absent';
    ticket.finTraitement = new Date();
    await ticket.save();

    file.ticketEnCours = null;
    file.stats.clientsAbsents = (file.stats.clientsAbsents || 0) + 1;
    await file.save();

    await recalculerPositions(file._id, io);

    res.json({ success: true, message: 'Client marque absent' });
  } catch (error) {
    res.status(500).json({ success: false, error: error.message });
  }
};
