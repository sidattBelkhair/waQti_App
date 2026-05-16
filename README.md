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
9. [Déploiement en production](#9-déploiement-en-production)
10. [WhatsApp OTP — Configuration](#10-whatsapp-otp--configuration)
11. [Tester l'API](#11-tester-lapi)
12. [Build APK Android](#12-build-apk-android)
13. [Comment ça marche — Flux complet](#13-comment-ça-marche--flux-complet)
14. [Roles et permissions](#14-roles-et-permissions)
15. [Base de données — Modèles](#15-base-de-données--modèles)

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
| **OTP** | **WhatsApp via Baileys** (gratuit, pas de SMS) |
| Déploiement backend | Render.com |
| Déploiement admin | Vercel |
| Notifications Push | Firebase Cloud Messaging |

---

## 3. Prérequis

### Pour le backend
- [Node.js 18+](https://nodejs.org/)
- Un compte [MongoDB Atlas](https://cloud.mongodb.com) (gratuit)
- **Un compte WhatsApp** pour envoyer les OTP (ton propre numéro suffit)

### Pour l'application mobile
- [Flutter SDK 3.x](https://flutter.dev/docs/get-started/install)
- Android Studio + SDK Android
- Java 17 (`org.gradle.java.home` configuré dans `gradle.properties`)

### Comptes nécessaires pour la production
- [Render.com](https://render.com) — backend (gratuit)
- [Vercel](https://vercel.com) — admin web (gratuit)
- [MongoDB Atlas](https://cloud.mongodb.com) — base de données (gratuit)

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
npm install
cp .env.example .env
# Remplis .env (voir section 8)
npm run dev
# Démarre sur http://localhost:5000
```

Au premier démarrage, le QR WhatsApp s'affiche dans le terminal. Scanne-le avec WhatsApp → la session est sauvegardée dans MongoDB.

### Lancer l'app mobile

```bash
cd mobile-app
flutter pub get
flutter run
```

### Lancer le dashboard admin

```bash
cd admin-web/frontend
npm install
echo "VITE_API_URL=http://localhost:5000/api" > .env
npm run dev
# Disponible sur http://localhost:5173
```

---

## 5. Backend — API Node.js

### Structure des fichiers

```
backend/
├── server.js
└── src/
    ├── config/
    │   ├── database.js
    │   └── jwt.js
    ├── models/
    │   ├── User.js
    │   ├── Etablissement.js
    │   ├── Service.js
    │   ├── Ticket.js
    │   ├── File.js
    │   └── WhatsappSession.js    ← Session WhatsApp persistée en MongoDB
    ├── controllers/
    ├── routes/
    ├── middleware/
    ├── sockets/
    └── utils/
        ├── whatsapp.js           ← Connexion WhatsApp via Baileys
        ├── sms.js                ← Envoi OTP (WhatsApp ou console fallback)
        └── otp.js                ← Génération code OTP 6 chiffres
```

### Endpoints API

#### Auth — `/api/auth`

| Méthode | Endpoint | Description |
|---|---|---|
| POST | `/register` | Créer un compte → envoie OTP WhatsApp |
| POST | `/login` | Se connecter |
| POST | `/verify-otp` | Valider le code OTP |
| POST | `/forgot-password` | Reset mot de passe → envoie code WhatsApp |
| POST | `/reset-password` | Changer le mot de passe avec le code reçu |
| POST | `/logout` | Se déconnecter |
| GET | `/profile` | Voir son profil |
| PUT | `/profile` | Modifier son profil |

#### Établissements — `/api/etablissements`

| Méthode | Endpoint | Description |
|---|---|---|
| GET | `/` | Rechercher des établissements |
| GET | `/:id` | Détails d'un établissement |
| GET | `/:id/services` | Services d'un établissement |
| PUT | `/:id` | Modifier (gestionnaire) |
| POST | `/:id/services` | Créer un service |

#### Tickets — `/api/tickets`

| Méthode | Endpoint | Description |
|---|---|---|
| GET | `/mes-tickets` | Mes tickets |
| POST | `/` | Prendre un ticket immédiat |
| POST | `/rdv` | Prendre un RDV |
| DELETE | `/:id/annuler` | Annuler un ticket |

#### Files d'attente — `/api/files`

| Méthode | Endpoint | Description |
|---|---|---|
| GET | `/:serviceId` | État de la file |
| POST | `/:serviceId/appeler-suivant` | Appeler le prochain (gestionnaire) |

#### Admin — `/api/admin` *(token admin requis)*

| Méthode | Endpoint | Description |
|---|---|---|
| GET | `/stats` | Statistiques globales |
| GET | `/users` | Liste des utilisateurs |
| PATCH | `/users/:id/statut` | Suspendre/activer |
| GET | `/etablissements` | Liste des établissements |

#### WhatsApp & Santé

| Méthode | Endpoint | Description |
|---|---|---|
| GET | `/api/whatsapp/qr` | **QR code WhatsApp** (image dans navigateur) |
| GET | `/api/health` | Vérifier que le serveur tourne |

---

## 6. Application mobile — Flutter

### Changer l'URL de l'API

Ouvre [mobile-app/lib/config/api_config.dart](mobile-app/lib/config/api_config.dart) :

```dart
class ApiConfig {
  // PRODUCTION
  static const String baseUrl = 'https://waqti-app.onrender.com/api';

  // LOCAL (décommente pour tester en local)
  // static const String baseUrl = 'http://192.168.X.X:5000/api';
}
```

### Numéros de téléphone

L'app accepte les numéros mauritaniens en format court (`XXXXXXXX`) ou complet (`+222XXXXXXXX`). Le backend normalise automatiquement vers `+222XXXXXXXX`.

### Langues supportées

L'app supporte le **Français** et l'**Arabe (RTL)**.

---

## 7. Dashboard Admin — React

**URL production :** `https://wa-qti-app.vercel.app`

### Créer un compte admin (première fois)

1. Va sur `https://wa-qti-app.vercel.app/login`
2. Clique sur l'onglet **"Créer admin"**
3. Remplis :
   - Nom complet
   - Téléphone (ex: `41585215`)
   - Mot de passe (min 8 caractères)
   - Clé secrète admin : `SIDATTBELKHAIR_WAQTI`
4. Clique **"Créer le compte admin"**

### Se connecter

Onglet **Connexion** → Téléphone + Mot de passe choisi lors de la création.

---

## 8. Variables d'environnement

### Backend — `/backend/.env`

```env
PORT=5000
NODE_ENV=development
CORS_ORIGIN=*

# MongoDB Atlas
MONGODB_URI=mongodb+srv://USER:PASS@cluster.mongodb.net/waqti

# JWT
JWT_ACCESS_SECRET=cle_secrete_longue_et_aleatoire
JWT_REFRESH_SECRET=autre_cle_secrete_differente

# Sécurité admin
ADMIN_CREATE_SECRET=SIDATTBELKHAIR_WAQTI

# Firebase (optionnel — notifications push)
FIREBASE_PROJECT_ID=waqti-app
FIREBASE_CLIENT_EMAIL=firebase-adminsdk@waqti-app.iam.gserviceaccount.com
FIREBASE_PRIVATE_KEY=your_key
```

> **Note** : Pas de clé SMS/Twilio/Infobip — les OTP sont envoyés par **WhatsApp gratuitement**.

### Admin Frontend — `/admin-web/frontend/.env`

```env
VITE_API_URL=https://waqti-app.onrender.com/api
```

---

## 9. Déploiement en production

### Backend → Render.com

**URL :** `https://waqti-app.onrender.com`

```bash
git push origin main
# Render redéploie automatiquement
```

Variables à configurer dans Render → **Environment** :

| Variable | Valeur |
|---|---|
| `NODE_ENV` | `production` |
| `MONGODB_URI` | URI MongoDB Atlas |
| `JWT_ACCESS_SECRET` | clé aléatoire |
| `JWT_REFRESH_SECRET` | autre clé |
| `ADMIN_CREATE_SECRET` | `SIDATTBELKHAIR_WAQTI` |

### Admin Web → Vercel

**URL :** `https://wa-qti-app.vercel.app`

Déploiement automatique depuis GitHub. Variable à configurer :

| Variable | Valeur |
|---|---|
| `VITE_API_URL` | `https://waqti-app.onrender.com/api` |

### MongoDB Atlas — Autoriser toutes les IPs

cloud.mongodb.com → **Network Access** → **+ Add IP Address** → `0.0.0.0/0`

---

## 10. WhatsApp OTP — Configuration

WaQti utilise **Baileys** (WhatsApp Web API) pour envoyer les codes OTP via WhatsApp — **gratuit, sans quota**.

### Comment ça marche

```
1. Render démarre → charge la session WhatsApp depuis MongoDB
2. Si pas de session → génère un QR code
3. Tu scannes le QR avec ton WhatsApp → session active
4. Session sauvegardée dans MongoDB → survit aux redémarrages
5. Quand un user s'inscrit → OTP envoyé via WhatsApp au format :
   🕐 WaQti — Votre code : 847291 — Expire dans 5 min
```

### Scanner le QR (première fois ou après déconnexion)

1. Ouvre dans le navigateur : `https://waqti-app.onrender.com/api/whatsapp/qr`
2. Scanne le QR avec ton WhatsApp (Paramètres → Appareils connectés → Connecter un appareil)
3. La page se rafraîchit automatiquement toutes les 15s
4. Une fois connecté, la page affiche "WhatsApp déjà connecté"

### Vérifier l'état de connexion

Dans les logs Render, tu verras :
```
[WhatsApp] Connecte ! OTP envoyes via WhatsApp   ← OK
[WhatsApp] QR pret - ouvre: /api/whatsapp/qr     ← À scanner
[WhatsApp] Session expiree - suppression...       ← Disconnect, nouveau QR auto
```

### Format des numéros

Le backend accepte et normalise automatiquement :
- `49484602` → `+22249484602`
- `+22249484602` → `+22249484602`

### Si WhatsApp n'est pas connecté

L'OTP s'affiche dans les logs Render (console fallback) et une case "Mode test" apparaît dans l'app pour permettre les tests sans WhatsApp.

---

## 11. Tester l'API

```bash
BASE="https://waqti-app.onrender.com/api"

# Health check
curl $BASE/health

# Inscription (OTP envoyé sur WhatsApp)
curl -s -X POST "$BASE/auth/register" \
  -H "Content-Type: application/json" \
  -d '{"nom":"Test","telephone":"41585215","motDePasse":"Test@1234","role":"client"}'

# Vérifier OTP
curl -s -X POST "$BASE/auth/verify-otp" \
  -H "Content-Type: application/json" \
  -d '{"userId":"USERID_ICI","code":"CODE_WHATSAPP"}'

# Lister les établissements
curl -s "$BASE/etablissements"
```

---

## 12. Build APK Android

```bash
cd mobile-app

# S'assurer que Java 17 est utilisé (gradle.properties déjà configuré)
flutter build apk --release --split-per-abi

# APK à envoyer : app-arm64-v8a-release.apk
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk ~/WaQti.apk
```

> **Note Java** : Le fichier `android/gradle.properties` contient `org.gradle.java.home=/usr/lib/jvm/java-17-openjdk` pour éviter les conflits avec Java 21 (Android Studio JBR).

---

## 13. Comment ça marche — Flux complet

### Flux OTP WhatsApp

```
1. User entre son numéro → /api/auth/register
2. Backend normalise le numéro : 49484602 → +22249484602
3. Génère code OTP 6 chiffres (expire dans 5 min)
4. Envoie via WhatsApp Baileys :
   🕐 WaQti — Votre code de vérification : 847291 — Expire dans 5 minutes.
5. User reçoit le message WhatsApp et entre le code dans l'app
6. Backend vérifie → retourne accessToken + refreshToken
7. Tokens stockés dans SharedPreferences sur le téléphone
```

### Flux Client (prendre un ticket)

```
1. Inscription → OTP WhatsApp → connexion
2. Recherche un établissement
3. Choisit un service
4. Prend un ticket virtuel → position dans la file
5. Suivi temps réel via WebSocket
6. Notification quand c'est son tour
```

### Flux Gestionnaire

```
1. Connexion avec compte gestionnaire
2. Dashboard de son établissement en temps réel
3. "Appeler suivant" → client notifié
4. Scanner QR code du ticket pour valider la présence
```

### Temps réel (WebSocket)

Socket.IO gère les mises à jour en direct :
- Ticket pris → file mise à jour pour tous
- Gestionnaire appelle le suivant → client notifié instantanément

---

## 14. Roles et permissions

| Action | Client | Gestionnaire | Admin |
|---|---|---|---|
| S'inscrire / se connecter | ✅ | ✅ | ✅ |
| Prendre un ticket | ✅ | — | — |
| Voir sa position dans la file | ✅ | — | — |
| Prendre un RDV | ✅ | — | — |
| Laisser un avis | ✅ | — | — |
| Gérer son établissement | — | ✅ | — |
| Appeler le suivant | — | ✅ | — |
| Scanner QR code ticket | — | ✅ | — |
| Voir tous les utilisateurs | — | — | ✅ |
| Suspendre un compte | — | — | ✅ |
| Activer un établissement | — | — | ✅ |
| Voir les stats globales | — | — | ✅ |

---

## 15. Base de données — Modèles

### User
| Champ | Type | Description |
|---|---|---|
| `telephone` | String | Format `+222XXXXXXXX` (normalisé automatiquement) |
| `nom` | String | Nom complet |
| `motDePasse` | String | Haché avec bcryptjs |
| `role` | Enum | `client` / `gestionnaire` / `admin` |
| `statut` | Enum | `actif` / `inactif` / `suspendu` |
| `otp` | Object | Code temporaire (code, expiresAt, attempts) |
| `refreshTokens` | Array | Tokens JWT |

### WhatsappSession *(nouveau)*
| Champ | Type | Description |
|---|---|---|
| `_id` | String | `"main"` (une seule session) |
| `data` | Object | Clés de chiffrement Baileys (creds + keys) |
| `updatedAt` | Date | Dernière mise à jour automatique |

### Ticket
| Champ | Type | Description |
|---|---|---|
| `numero` | String | Ex: "T-0042" |
| `statut` | Enum | `waiting` / `called` / `serving` / `completed` / `cancelled` |
| `position` | Number | Position en temps réel |
| `qrCode` | String | Pour validation physique au guichet |

---

## Liens utiles

- **Backend** : https://waqti-app.onrender.com/api/health
- **Admin Web** : https://wa-qti-app.vercel.app
- **QR WhatsApp** : https://waqti-app.onrender.com/api/whatsapp/qr
- **GitHub** : https://github.com/sidattBelkhair/waQti_App
- **MongoDB Atlas** : https://cloud.mongodb.com
- **Render Dashboard** : https://dashboard.render.com

---

*WaQti — Mauritanie 🇲🇷*
