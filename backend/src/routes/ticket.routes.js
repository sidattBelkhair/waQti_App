const router = require('express').Router();
const tickets = require('../controllers/ticket.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

router.use(authenticateToken);

router.get('/mes-tickets', tickets.getMesTickets);
router.get('/etablissement', tickets.getEtablissementTickets);
router.post('/', tickets.createTicket);
router.post('/rdv', tickets.createTicketRDV);
router.delete('/:id/annuler', tickets.cancelTicket);
router.post('/:id/signaler-retard', tickets.signalRetard);
router.post('/:id/valider-presence', tickets.validerPresence);
router.post('/scan/:numero/valider', tickets.validerPresenceByNumero);

module.exports = router;
