# WaQti - Mon Temps

> Application de Gestion des Files d'Attente - Mauritanie
> Digitaliser l'attente. Respecter le temps de chacun.

## Architecture

| Composant | Technologie |
|-----------|-------------|
| API Mobile Backend | Node.js + Express |
| App Mobile | Flutter (Android) |
| Interface Admin Web | React + Node.js Express |
| Base de donnees | MongoDB |
| Temps reel | Socket.io |
| Notifications Push | Firebase FCM |
| Auth OTP SMS | Twilio |

## Demarrage rapide

```bash
cd backend && cp .env.example .env && npm install && npm run dev
```

## Modules

| Module | Description |
|--------|-------------|
| Authentification | Inscription, login OTP SMS, JWT, profil |
| Tickets & Files | Creation tickets, file FIFO, priorites, temps reel |
| Etablissements | Profils, services, personnel, recherche geo, avis |
| Admin Web | Dashboard, gestion etablissements/users, stats |
