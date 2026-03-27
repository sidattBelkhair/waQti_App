const router = require('express').Router();
const tickets = require('../controllers/ticket.controller');
const files = require('../controllers/file.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

router.use(authenticateToken);

router.get('/:serviceId', files.getFileStatus);
router.get('/:serviceId/position', files.getPosition);
router.post('/:serviceId/appeler-suivant', tickets.appelSuivant);
router.post('/:serviceId/absent', tickets.marquerAbsent);

module.exports = router;
