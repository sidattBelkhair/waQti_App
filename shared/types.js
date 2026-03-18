/**
 * WaQti - Schemas JSON partages
 * Reference pour les modeles Mongoose, reponses API,
 * modeles Dart (Flutter) et interfaces React (Admin)
 */
const TicketSchema = {
  numero: 'String - WQ250317-0001',
  utilisateur: 'ObjectId -> User',
  etablissement: 'ObjectId -> Etablissement',
  service: 'ObjectId -> Service',
  mode: 'distance | sur_place | rdv',
  statut: 'en_attente | en_cours | termine | annule | absent',
  priorite: '1=urgent | 2=age | 3=enceinte | 4=normal',
  position: 'Number',
  tempsEstime: 'Number (minutes)',
};

const WebSocketEvents = {
  file_updated: {
    description: 'Envoye a toute la room du service quand la file change',
    payload: '{ serviceId, ticketId, position, tempsEstime, totalEnAttente }',
  },
  votre_tour_approche: {
    description: 'Envoye au client quand il est 2e dans la file',
    payload: '{ ticketId, position: 1 }',
  },
  votre_tour: {
    description: 'Envoye au client quand c est son tour',
    payload: '{ ticketId, numero, guichet }',
  },
  ticket_annule: {
    description: 'Envoye quand un ticket est annule',
    payload: '{ ticketId, serviceId }',
  },
};

module.exports = { TicketSchema, WebSocketEvents };
