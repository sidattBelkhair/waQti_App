/**
 * WaQti - Constantes partagees entre tous les modules
 * Source unique de verite pour les constantes.
 */
module.exports = {
  USER_STATUS: {
    ACTIVE: 'actif',
    SUSPENDED: 'suspendu',
    UNVERIFIED: 'non_verifie',
  },

  ETAB_STATUS: {
    PENDING: 'en_attente',
    ACTIVE: 'actif',
    SUSPENDED: 'suspendu',
  },

  TICKET_STATUS: {
    WAITING: 'en_attente',
    IN_PROGRESS: 'en_cours',
    COMPLETED: 'termine',
    CANCELLED: 'annule',
    ABSENT: 'absent',
  },

  PRIORITY: {
    URGENT: 1,
    ELDERLY: 2,
    PREGNANT: 3,
    NORMAL: 4,
  },

  TICKET_MODE: {
    DISTANCE: 'distance',
    ON_SITE: 'sur_place',
    APPOINTMENT: 'rdv',
  },

  ROLES: {
    CLIENT: 'client',
    MANAGER: 'gestionnaire',
    ADMIN: 'admin',
  },

  ETAB_TYPES: [
    'hopital', 'banque', 'ambassade', 'mairie',
    'poste', 'telecom', 'universite', 'autre',
  ],

  WS_EVENTS: {
    FILE_UPDATED: 'file_updated',
    YOUR_TURN_APPROACHING: 'votre_tour_approche',
    YOUR_TURN: 'votre_tour',
    TICKET_CANCELLED: 'ticket_annule',
    CLIENT_ABSENT: 'client_absent',
  },

  ERRORS: {
    UNAUTHORIZED: 'Non autorise',
    FORBIDDEN: 'Acces refuse',
    NOT_FOUND: 'Ressource non trouvee',
    VALIDATION: 'Erreur de validation',
    SERVER: 'Erreur interne du serveur',
    DUPLICATE: 'Cette ressource existe deja',
  },

  HTTP: {
    OK: 200, CREATED: 201, BAD_REQUEST: 400,
    UNAUTHORIZED: 401, FORBIDDEN: 403, NOT_FOUND: 404,
    CONFLICT: 409, TOO_MANY: 429, SERVER_ERROR: 500,
  },
};
