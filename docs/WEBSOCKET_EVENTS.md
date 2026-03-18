# WaQti - Events WebSocket

## Connexion
```javascript
socket.emit('join_service', serviceId);
socket.emit('join_user', userId);
```

## Events
- **file_updated** : file change -> { serviceId, ticketId, position, tempsEstime, totalEnAttente }
- **votre_tour_approche** : client 2e -> { ticketId, position: 1 }
- **votre_tour** : c est son tour -> { ticketId, numero, guichet }
- **ticket_annule** : ticket annule -> { ticketId, serviceId }
