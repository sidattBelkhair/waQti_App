const router = require('express').Router();
const tickets = require('../controllers/ticket.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

router.use(authenticateToken);

router.post('/', tickets.createTicket);
router.post('/rdv', tickets.createTicketRDV);
router.delete('/:id/annuler', tickets.cancelTicket);
router.post('/:id/signaler-retard', tickets.signalRetard);
router.post('/:id/valider-presence', tickets.validerPresence);

module.exports = router;
