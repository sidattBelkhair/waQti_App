const router = require('express').Router();
const etab = require('../controllers/etablissement.controller');
const { authenticateToken } = require('../middleware/auth.middleware');

// Routes publiques
router.get('/', etab.searchEtablissements);
router.get('/:id', etab.getEtablissement);
router.get('/:id/avis', etab.getAvis);

// Routes protegees
router.use(authenticateToken);
router.put('/:id', etab.updateEtablissement);
router.delete('/:id', etab.deleteEtablissement);
router.post('/:id/fermetures', etab.addFermeture);
router.get('/:id/services', etab.getServices);
router.post('/:id/services', etab.createService);
router.put('/:id/services/:serviceId', etab.updateService);
router.delete('/:id/services/:serviceId', etab.deleteService);
router.post('/services/:serviceId/guichets', etab.addGuichet);
router.get('/:id/personnel', etab.getPersonnel);
router.post('/:id/personnel', etab.addAgent);
router.put('/:id/personnel/:agentId/disponibilites', etab.updateDisponibilites);
router.post('/:id/personnel/:agentId/conges', etab.addConge);
router.post('/:id/avis', etab.createAvis);

module.exports = router;
