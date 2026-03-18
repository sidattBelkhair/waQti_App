const router = require('express').Router();
const admin = require('../controllers/admin.controller');
const { authenticateToken, authorizeRoles } = require('../middleware/auth.middleware');

// Toutes les routes admin necessitent un token JWT + role admin
router.use(authenticateToken, authorizeRoles('admin'));

// Stats
router.get('/stats', admin.getStats);

// Etablissements
router.get('/etablissements', admin.getEtablissements);
router.post('/etablissements', admin.createEtablissement);
router.patch('/etablissements/:id/statut', admin.updateEtablissementStatut);
router.delete('/etablissements/:id', admin.deleteEtablissement);

// Utilisateurs
router.get('/users', admin.getUsers);
router.get('/users/:id', admin.getUserById);
router.patch('/users/:id/statut', admin.updateUserStatut);
router.delete('/users/:id', admin.deleteUser);

module.exports = router;
