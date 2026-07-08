const router = require('express').Router();
const gestionnaire = require('../controllers/gestionnaire.controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');

router.use(authenticateToken, authorizeRoles('gestionnaire'));

router.get('/stats/today', gestionnaire.getStatsToday);

module.exports = router;
