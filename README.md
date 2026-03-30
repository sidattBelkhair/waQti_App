# WaQti — Système de Gestion de File d'Attente

> **"Digitaliser l'attente. Respecter le temps de chacun."**
>
> Application mobile de gestion de file d'attente conçue pour la Mauritanie.

---

## Table des Matières

1. [C'est quoi WaQti ?](#1-cest-quoi-waqti-)
2. [Architecture du projet](#2-architecture-du-projet)
3. [Prérequis](#3-prérequis)
4. [Installation et lancement local](#4-installation-et-lancement-local)
5. [Backend — API Node.js](#5-backend--api-nodejs)
6. [Application mobile — Flutter](#6-application-mobile--flutter)
7. [Dashboard Admin — React](#7-dashboard-admin--react)
8. [Variables d'environnement](#8-variables-denvironnement)
9. [Déploiement en production (Render)](#9-déploiement-en-production-render)
10. [Tester l'API](#10-tester-lapi)
11. [Build APK Android](#11-build-apk-android)
12. [Comment ça marche — Flux complet](#12-comment-ça-marche--flux-complet)
13. [Roles et permissions](#13-roles-et-permissions)
14. [Base de données — Modèles](#14-base-de-données--modèles)

---

## 1. C'est quoi WaQti ?

**WaQti** est une application de gestion de file d'attente pour les établissements mauritaniens (hôpitaux, banques, communes, préfectures...).

**Problème résolu** : Les gens attendent des heures debout dans des files. WaQti leur permet de prendre un ticket virtuel depuis leur téléphone, de suivre leur position en temps réel, et d'être notifiés quand c'est leur tour.

**3 types d'utilisateurs :**

| Rôle | Ce qu'il peut faire |
|---|---|
| **Client** | Prendre un ticket, suivre sa position, prendre RDV |
| **Gestionnaire** | Gérer son établissement, ses services, appeler le suivant |
| **Admin** | Superviser tout le système via le web dashboard |

---

## 2. Architecture du projet

```
waQti_App/
├── backend/          # API Node.js + Express + MongoDB
├── mobile-app/       # Application Flutter (Android/iOS)
├── admin-web/        # Dashboard admin React + Vite
└── render.yaml       # Config de déploiement Render
```

**Stack technique :**

| Composant | Technologie |
|---|---|
| API Backend | Node.js 22, Express 4, MongoDB Atlas, Socket.IO |
| Mobile App | Flutter 3, Dart, Provider, Dio, Socket.IO |
| Admin Web | React 18, Vite, Tailwind CSS, Recharts |
| Base de données | MongoDB Atlas (cloud) |
| SMS OTP | Infobip (100 SMS/mois gratuits) |
| Déploiement | Render.com (backend gratuit) |
| Notifications Push | Firebase Cloud Messaging |

---

## 3. Prérequis

Installe ces outils avant de commencer :

### Pour le backend
- [Node.js 18+](https://nodejs.org/) → vérifie avec `node --version`
- Un compte [MongoDB Atlas](https://cloud.mongodb.com) (gratuit)

### Pour l'application mobile
- [Flutter SDK 3.x](https://flutter.dev/docs/get-started/install) → vérifie avec `flutter --version`
- Android Studio + SDK Android
- Un téléphone Android (mode développeur activé) ou un émulateur

### Comptes nécessaires pour la production
- [Render.com](https://render.com) — hébergement backend (gratuit)
- [MongoDB Atlas](https://cloud.mongodb.com) — base de données (gratuit)
- [Infobip](https://portal.infobip.com) — SMS OTP (100 SMS/mois gratuits)

---

## 4. Installation et lancement local

### Cloner le projet

```bash
git clone https://github.com/sidattBelkhair/waQti_App.git
cd waQti_App
```

### Lancer le backend

```bash
cd backend

# Installer les dépendances
npm install

# Créer le fichier de configuration
cp .env.example .env
# Ouvre .env et remplis les variables (voir section 8)

# Lancer en mode développement (redémarre automatiquement)
npm run dev

# Le serveur démarre sur http://localhost:5000
# Tester : curl http://localhost:5000/api/health
```

### Lancer l'app mobile

```bash
cd mobile-app

# Installer les dépendances Flutter
flutter pub get

# Vérifier que tout est OK
flutter doctor

# IMPORTANT : changer l'URL vers ton serveur local
# Ouvre lib/config/api_config.dart
# Commente la ligne "production" et décommente la ligne "local"
# Remplace l'IP par celle de ton PC (voir ip addr show)

# Connecte ton téléphone Android en USB (mode debug activé)
# Ou lance un émulateur depuis Android Studio

# Lancer l'application
flutter run
```

### Lancer le dashboard admin

```bash
cd admin-web/frontend

# Installer les dépendances
npm install

# Créer le fichier .env
echo "VITE_API_URL=http://localhost:5000/api" > .env

# Lancer en mode développement
npm run dev
# Dashboard disponible sur http://localhost:5173
```

---

## 5. Backend — API Node.js

### Structure des fichiers

```
backend/
├── server.js                   # Point d'entrée — démarre le serveur
├── package.json
├── .env                        # Variables d'environnement (à créer)
└── src/
    ├── config/
    │   ├── database.js         # Connexion MongoDB
    │   ├── jwt.js              # Config tokens JWT
    │   └── firebase.js         # Config notifications push
    ├── models/                 # Schémas MongoDB (structure des données)
    │   ├── User.js
    │   ├── Etablissement.js
    │   ├── Service.js
    │   ├── Ticket.js
    │   ├── File.js             # File d'attente
    │   ├── Agent.js
    │   └── Avis.js
    ├── controllers/            # Logique métier (ce que fait chaque endpoint)
    ├── routes/                 # Définition des URLs de l'API
    ├── middleware/             # Auth JWT, rate limiting, gestion d'erreurs
    ├── sockets/                # WebSocket temps réel (Socket.IO)
    └── utils/                  # SMS, OTP, QR code
```

### Scripts npm

```bash
npm start      # Production (utilisé par Render)
npm run dev    # Développement avec rechargement automatique (nodemon)
npm test       # Tests Jest
```

### Tous les endpoints API

#### Auth — `/api/auth`

| Méthode | Endpoint | Description | Auth |
|---|---|---|---|
| POST | `/register` | Créer un compte | Non |
| POST | `/login` | Se connecter (envoie OTP) | Non |
| POST | `/verify-otp` | Valider le code SMS | Non |
| POST | `/forgot-password` | Demander reset mot de passe | Non |
| POST | `/reset-password` | Changer le mot de passe | Non |
| POST | `/logout` | Se déconnecter | Oui |
| GET | `/profile` | Voir son profil | Oui |
| PUT | `/profile` | Modifier son profil | Oui |
| POST | `/change-phone` | Changer son numéro | Oui |
| POST | `/register-etablissement` | Enregistrer un établissement | Oui |
| GET | `/my-etablissement` | Voir son établissement (gestionnaire) | Oui |

#### Établissements — `/api/etablissements`

| Méthode | Endpoint | Description | Auth |
|---|---|---|---|
| GET | `/` | Rechercher des établissements | Non |
| GET | `/:id` | Détails d'un établissement | Non |
| GET | `/:id/services` | Services d'un établissement | Non |
| GET | `/:id/avis` | Avis d'un établissement | Non |
| PUT | `/:id` | Modifier un établissement | Oui (gestionnaire) |
| POST | `/:id/services` | Créer un service | Oui (gestionnaire) |
| POST | `/:id/avis` | Laisser un avis | Oui |

#### Tickets — `/api/tickets`

| Méthode | Endpoint | Description | Auth |
|---|---|---|---|
| GET | `/mes-tickets` | Mes tickets | Oui |
| POST | `/` | Prendre un ticket immédiat | Oui |
| POST | `/rdv` | Prendre un RDV | Oui |
| DELETE | `/:id/annuler` | Annuler un ticket | Oui |
| POST | `/:id/signaler-retard` | Signaler un retard | Oui |
| POST | `/scan/:numero/valider` | Valider présence par QR code | Oui |

#### Files d'attente — `/api/files`

| Méthode | Endpoint | Description | Auth |
|---|---|---|---|
| GET | `/:serviceId` | État de la file | Oui |
| GET | `/:serviceId/position` | Ma position dans la file | Oui |
| POST | `/:serviceId/appeler-suivant` | Appeler le prochain client | Oui (gestionnaire) |
| POST | `/:serviceId/absent` | Marquer client absent | Oui (gestionnaire) |

#### Admin — `/api/admin` *(token admin requis)*

| Méthode | Endpoint | Description |
|---|---|---|
| GET | `/stats` | Statistiques globales |
| GET | `/users` | Liste des utilisateurs |
| PATCH | `/users/:id/statut` | Suspendre/activer un user |
| DELETE | `/users/:id` | Supprimer un user |
| GET | `/etablissements` | Liste des établissements |
| PATCH | `/etablissements/:id/statut` | Activer/suspendre |
| DELETE | `/etablissements/:id` | Supprimer |

#### Santé

| Méthode | Endpoint | Description |
|---|---|---|
| GET | `/api/health` | Vérifier que le serveur tourne |

---

## 6. Application mobile — Flutter

### Structure des fichiers

```
mobile-app/lib/
├── main.dart                     # Point d'entrée Flutter
├── config/
│   ├── api_config.dart           # URL de l'API ← MODIFIER ICI
│   └── theme.dart                # Couleurs et thème de l'app
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart         # Écran de connexion
│   │   ├── register_screen.dart      # Inscription
│   │   ├── otp_screen.dart           # Saisie du code SMS
│   │   ├── forgot_password_screen.dart
│   │   └── reset_password_screen.dart
│   ├── home/
│   │   └── home_screen.dart          # Accueil client
│   ├── search/
│   │   └── search_screen.dart        # Recherche d'établissements
│   ├── ticket/
│   │   ├── create_ticket_screen.dart  # Prendre un ticket
│   │   ├── ticket_detail_screen.dart  # Détails du ticket
│   │   ├── ticket_tracking_screen.dart # Suivi temps réel
│   │   └── rdv_screen.dart            # Rendez-vous
│   ├── profile/
│   │   └── profile_screen.dart        # Profil + changement de langue
│   ├── etablissement/
│   │   ├── etablissement_detail_screen.dart
│   │   ├── etablissement_dashboard_screen.dart
│   │   ├── register_etablissement_screen.dart
│   │   ├── gestion_services_screen.dart
│   │   └── qr_scanner_screen.dart     # Scanner QR code
│   └── gestionnaire/
│       ├── gestionnaire_home_screen.dart
│       ├── gestionnaire_etablissement_screen.dart
│       ├── gestionnaire_services_screen.dart
│       └── gestionnaire_tickets_screen.dart
├── providers/
│   ├── auth_provider.dart        # État global d'authentification
│   └── locale_provider.dart      # Langue active (FR/AR)
├── services/
│   ├── api_service.dart          # Client HTTP (Dio) vers l'API
│   └── socket_service.dart       # Connexion temps réel (Socket.IO)
├── models/                       # Classes Dart pour les données
└── l10n/
    └── app_strings.dart          # Traductions FR/AR
```

### Changer l'URL de l'API

Ouvre [mobile-app/lib/config/api_config.dart](mobile-app/lib/config/api_config.dart) :

```dart
class ApiConfig {
  // PRODUCTION — actif par défaut
  static const String baseUrl = 'https://waqti-app.onrender.com/api';

  // LOCAL — décommente pour tester en local
  // Trouve ton IP avec : ip addr show (Linux) ou ipconfig (Windows)
  // static const String baseUrl = 'http://192.168.1.XXX:5000/api';

  static const Duration timeout = Duration(seconds: 90);
}
```

### Couleurs de l'application

| Nom | Hex | Usage |
|---|---|---|
| Primary | `#2563EB` | Bleu principal, boutons, appbar |
| Accent | `#06B6D4` | Cyan, dégradés |
| Success | `#059669` | Vert, ticket validé |
| Warning | `#F59E0B` | Ambre, en attente |
| Danger | `#DC2626` | Rouge, annulé, erreur |
| Background | `#F1F5F9` | Fond gris clair |

### Langues supportées

L'app supporte le **Français** et l'**Arabe (RTL)**.
Le bouton de langue est visible sur l'écran de connexion et dans le profil.

---

## 7. Dashboard Admin — React

### Lancer le dashboard

```bash
cd admin-web/frontend
npm install
npm run dev
# Disponible sur http://localhost:5173
```

### Pages disponibles

| Page | Description |
|---|---|
| Connexion | Login admin avec numéro de téléphone |
| Dashboard | Stats globales, graphiques en temps réel |
| Établissements | Liste, activation, suspension des établissements |
| Utilisateurs | Gestion des comptes (suspendre, supprimer) |
| Configuration | Paramètres système |

### Créer un compte admin

```bash
cd backend
node scripts/create-admin.js
```

---

## 8. Variables d'environnement

### Backend — `/backend/.env`

```env
# Serveur
PORT=5000
NODE_ENV=development          # Mettre "production" sur Render
CORS_ORIGIN=*

# MongoDB Atlas
# Récupère l'URI depuis cloud.mongodb.com → Connect → Drivers
MONGODB_URI=mongodb+srv://USERNAME:PASSWORD@cluster.mongodb.net/waqti

# JWT — mets des chaînes aléatoires longues (min 32 caractères)
JWT_ACCESS_SECRET=mets_ici_une_cle_secrete_longue_et_aleatoire
JWT_REFRESH_SECRET=mets_ici_une_autre_cle_secrete_differente

# Infobip SMS (recommandé pour +222 Mauritanie)
# Récupère depuis portal.infobip.com → API Keys
INFOBIP_API_KEY=ta_cle_api_infobip
INFOBIP_BASE_URL=xxxxx.api.infobip.com   # ton sous-domaine Infobip
INFOBIP_SENDER=WaQti

# Twilio SMS (optionnel — fallback si pas Infobip)
TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxx
TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxx
TWILIO_PHONE_NUMBER=+1xxxxxxxxxx

# Firebase (optionnel — pour notifications push)
FIREBASE_PROJECT_ID=waqti-app
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@waqti-app.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY="-----BEGIN PRIVATE KEY-----\n...\n-----END PRIVATE KEY-----\n"
```

### Admin Frontend — `/admin-web/frontend/.env`

```env
VITE_API_URL=https://waqti-app.onrender.com/api
```

---

## 9. Déploiement en production (Render)

Le backend est déployé automatiquement depuis GitHub sur [Render.com](https://render.com).

**URL de production :** `https://waqti-app.onrender.com`

### Étapes de déploiement

1. Push ton code sur GitHub
2. Connecte le repo à Render (déjà configuré via `render.yaml`)
3. Configure les variables d'environnement sur Render → **Environment**
4. Clic **Manual Deploy** → **Deploy latest commit**

### Variables à configurer sur Render

| Variable | Valeur |
|---|---|
| `NODE_ENV` | `production` |
| `PORT` | `10000` |
| `MONGODB_URI` | URI MongoDB Atlas |
| `JWT_ACCESS_SECRET` | clé secrète aléatoire |
| `JWT_REFRESH_SECRET` | autre clé secrète |
| `INFOBIP_API_KEY` | clé depuis portal.infobip.com |
| `INFOBIP_BASE_URL` | sous-domaine Infobip (ex: `6z9xdz.api.infobip.com`) |
| `INFOBIP_SENDER` | `WaQti` |

### Autoriser Render dans MongoDB Atlas

Render utilise des IPs dynamiques → il faut autoriser toutes les IPs :

1. [cloud.mongodb.com](https://cloud.mongodb.com) → **Network Access**
2. **+ Add IP Address** → **Allow Access from Anywhere** (`0.0.0.0/0`)
3. **Confirm** — attends 1-2 min que le statut passe à "Active"

### Redéployer après un changement

```bash
git add .
git commit -m "description du changement"
git push origin main
# Render redéploie automatiquement
```

> **Plan gratuit Render** : le service dort après 15 min d'inactivité. La première requête prend 50-90 secondes pour réveiller le serveur. C'est normal.

---

## 10. Tester l'API

### Health check — vérifier que le backend tourne

```bash
curl https://waqti-app.onrender.com/api/health
```

Réponse attendue :
```json
{"status": "OK", "app": "WaQti API", "version": "1.0.0"}
```

### Test complet — inscription + login

```bash
BASE="https://waqti-app.onrender.com/api"

# 1. INSCRIPTION
curl -s -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"nom":"Mon Nom","telephone":"+22249886974","motDePasse":"Test1234","role":"client"}' \
  | python3 -m json.tool
# → Récupère "userId" et "devOtp" dans la réponse

# 2. VÉRIFIER OTP (code reçu par SMS ou dans "devOtp")
curl -s -X POST "$BASE/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d '{"userId":"USERID_ICI","code":"OTP_ICI"}' \
  | python3 -m json.tool
# → Récupère "accessToken"

# 3. VOIR SON PROFIL
TOKEN="ACCESS_TOKEN_ICI"
curl -s "$BASE/auth/profile" \
  -H "Authorization: Bearer $TOKEN" \
  | python3 -m json.tool

# 4. CHERCHER DES ÉTABLISSEMENTS
curl -s "$BASE/etablissements" | python3 -m json.tool
```

---

## 11. Build APK Android

```bash
cd mobile-app

# Vérifier que Flutter est prêt
flutter doctor

# Build release (split par architecture)
flutter build apk --release --split-per-abi

# APKs générés :
# app-arm64-v8a-release.apk   ← téléphones modernes (envoie celui-ci)
# app-armeabi-v7a-release.apk ← anciens téléphones ARM 32-bit
# app-x86_64-release.apk      ← émulateurs x86

# Copier pour partager
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk ~/WaQti.apk
echo "APK prêt : ~/WaQti.apk"
```

> Envoie `app-arm64-v8a-release.apk` à tes amis — compatible avec 95% des Android modernes.

---

## 12. Comment ça marche — Flux complet

### Flux Client (prendre un ticket)

```
1. Ouvre l'app → écran de connexion
2. Inscription : numéro de téléphone + mot de passe
3. Reçoit un SMS avec code OTP à 6 chiffres
4. Entre le code dans l'app → connexion réussie
5. Recherche un établissement (hôpital, banque...)
6. Choisit un service (ex: "Consultation générale")
7. Prend un ticket virtuel → reçoit son numéro et position dans la file
8. L'app se met à jour en temps réel via WebSocket
9. Quand c'est son tour → notification push + SMS
10. Se présente au guichet → gestionnaire valide via QR code
```

### Flux Gestionnaire (gérer la file)

```
1. Connexion avec compte gestionnaire
2. Accède au dashboard de son établissement
3. Voit la liste des tickets en attente en temps réel
4. Appuie "Appeler suivant" → le client en tête est notifié
5. Peut marquer un client "absent" s'il ne se présente pas
6. Peut scanner le QR code du ticket pour valider la présence physique
```

### Flux SMS OTP

```
1. User tape son numéro → /api/auth/register ou /api/auth/login
2. Backend génère un code à 6 chiffres (expire dans 5 min)
3. Envoie le code via Infobip SMS au numéro
4. User reçoit le SMS et entre le code dans l'app
5. Backend vérifie le code → retourne accessToken + refreshToken
6. Les tokens sont stockés dans SharedPreferences sur le téléphone
7. Chaque requête API inclut le token : Authorization: Bearer <token>
8. Le token expire après 1h → refreshToken utilisé automatiquement
```

### Temps réel (WebSocket)

Le backend utilise **Socket.IO** pour les mises à jour en direct :
- Un client prend un ticket → la file se met à jour pour tous
- Le gestionnaire appelle le suivant → le client concerné est notifié
- La position dans la file se recalcule automatiquement

---

## 13. Roles et permissions

| Action | Client | Gestionnaire | Admin |
|---|---|---|---|
| S'inscrire / se connecter | ✅ | ✅ | ✅ |
| Prendre un ticket | ✅ | — | — |
| Voir sa position dans la file | ✅ | — | — |
| Prendre un RDV | ✅ | — | — |
| Laisser un avis | ✅ | — | — |
| Gérer son établissement | — | ✅ | — |
| Appeler le suivant | — | ✅ | — |
| Gérer les services et guichets | — | ✅ | — |
| Scanner QR code ticket | — | ✅ | — |
| Voir tous les utilisateurs | — | — | ✅ |
| Suspendre un compte | — | — | ✅ |
| Activer un établissement | — | — | ✅ |
| Voir les stats globales | — | — | ✅ |

---

## 14. Base de données — Modèles

### User
| Champ | Type | Description |
|---|---|---|
| `telephone` | String | Numéro unique (requis, format international) |
| `nom` | String | Nom complet |
| `motDePasse` | String | Haché avec bcryptjs (jamais retourné dans l'API) |
| `role` | Enum | `client` / `gestionnaire` / `admin` |
| `statut` | Enum | `actif` / `inactif` / `suspendu` |
| `nni` | String | Numéro National d'Identité |
| `otp` | Object | Code temporaire (code, expiresAt, attempts) |
| `refreshTokens` | Array | Tokens JWT de rafraîchissement |
| `fcmToken` | String | Token Firebase pour notifications push |

### Etablissement
| Champ | Type | Description |
|---|---|---|
| `nom` | String | Nom de l'établissement |
| `type` | Enum | `hopital` / `banque` / `commune` / `prefecture` / ... |
| `adresse` | Object | rue, ville, coordonnées GPS |
| `telephone` | String | |
| `responsable` | ObjectId | Référence vers le gestionnaire (User) |
| `statut` | Enum | `pending` / `actif` / `suspendu` |
| `horaires` | Object | Horaires d'ouverture par jour |
| `noteMoyenne` | Number | Note moyenne des avis (0-5) |
| `abonnement` | Object | `gratuit` / `standard` / `premium` |

### Service
| Champ | Type | Description |
|---|---|---|
| `nom` | String | Ex: "Consultation générale" |
| `etablissement` | ObjectId | Référence vers l'établissement |
| `dureeEstimee` | Number | Durée estimée par client (minutes) |
| `guichets` | Array | Guichets avec numéro, agent assigné, statut |
| `actif` | Boolean | Si le service accepte des tickets |

### Ticket
| Champ | Type | Description |
|---|---|---|
| `numero` | String | Numéro unique du ticket (ex: "T-0042") |
| `utilisateur` | ObjectId | Référence vers le client |
| `etablissement` | ObjectId | |
| `service` | ObjectId | |
| `mode` | Enum | `distance` / `rdv` / `immediate` |
| `statut` | Enum | `waiting` / `called` / `serving` / `completed` / `cancelled` / `no_show` |
| `position` | Number | Position dans la file (mis à jour en temps réel) |
| `priorite` | Number | 1 (urgent) à 5 (normal) |
| `rdv` | Object | Date et créneau si mode RDV |
| `qrCode` | String | Données QR pour validation physique au guichet |

### File (Queue)
| Champ | Type | Description |
|---|---|---|
| `service` | ObjectId | Un seul par service |
| `etablissement` | ObjectId | |
| `tickets` | Array | Tickets en attente (ordonnés par position) |
| `ticketEnCours` | ObjectId | Ticket actuellement en traitement |
| `stats` | Object | Clients traités, temps moyen, taux d'abandon |

---

## Liens utiles

- **Backend en production** : https://waqti-app.onrender.com/api/health
- **Repo GitHub** : https://github.com/sidattBelkhair/waQti_App
- **MongoDB Atlas** : https://cloud.mongodb.com
- **Render Dashboard** : https://dashboard.render.com
- **Infobip Portal** : https://portal.infobip.com

---

*WaQti — Mauritanie*
