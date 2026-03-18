# WaQti — Système de Gestion de File d'Attente

> **"Digitaliser l'attente. Respecter le temps de chacun."**
>
> Application mobile de gestion de file d'attente conçue pour la Mauritanie.
> Les citoyens prennent un ticket à distance, suivent leur position en temps réel,
> et reçoivent une notification quand c'est leur tour.

---

## Table des matières

1. [Vue d'ensemble](#vue-densemble)
2. [Architecture](#architecture)
3. [Prérequis](#prérequis)
4. [Installation](#installation)
5. [Configuration](#configuration)
6. [Démarrage](#démarrage)
7. [Guide de test complet](#guide-de-test-complet)
8. [API Reference](#api-reference)
9. [Comptes de test](#comptes-de-test)
10. [Problèmes fréquents](#problèmes-fréquents)

---

## Vue d'ensemble

WaQti est composé de 3 parties :

| Partie | Technologie | Description |
|--------|-------------|-------------|
| **Mobile App** | Flutter (Android) | Application pour clients et gestionnaires |
| **Admin Web** | React + Vite | Dashboard d'administration |
| **Backend** | Node.js + Express | API REST + WebSocket temps réel |
| **Base de données** | MongoDB Atlas | Hébergée dans le cloud |

### Les 3 rôles utilisateurs

| Rôle | Accès | Fonctions |
|------|-------|-----------|
| **Client** | App mobile | Chercher établissements, prendre/suivre tickets |
| **Gestionnaire** | App mobile | Gérer file d'attente, appeler clients |
| **Admin** | Web + API | Valider établissements, gérer utilisateurs |

---

## Architecture

```
┌─────────────────────┐     HTTP + WebSocket    ┌──────────────────────┐
│   App Mobile        │ ◄─────────────────────► │  Backend Node.js     │
│   Flutter           │                          │  Port 5000           │
├─────────────────────┤     HTTP REST           ├──────────────────────┤
│   Admin Web         │ ◄─────────────────────► │  MongoDB Atlas       │
│   React (Port 5173) │                          │  (Cloud)             │
└─────────────────────┘                          └──────────────────────┘
```

---

## Prérequis

### Pour le backend

- **Node.js** v18 ou supérieur → https://nodejs.org
- **npm** v9+

Vérifier :
```bash
node --version   # doit afficher v18+
npm --version    # doit afficher 9+
```

### Pour l'app mobile

- **Flutter SDK** 3.2.0+ → https://flutter.dev/docs/get-started/install
- **Android Studio** avec un émulateur Android (API 21+) OU un téléphone Android connecté en USB
- **Dart SDK** 3.2.0+

Vérifier :
```bash
flutter doctor    # doit tout afficher en vert
```

### Pour le dashboard admin (optionnel)

- **Node.js** v18+
- Un navigateur web moderne (Chrome, Firefox)

---

## Installation

### 1. Récupérer le projet

```bash
# Si vous avez reçu une archive .zip, extrayez-la
# Le dossier s'appelle waQti_App/
cd waQti_App/
```

### 2. Installer les dépendances du backend

```bash
cd backend/
npm install
```

### 3. Installer les dépendances de l'app mobile

```bash
cd mobile-app/
flutter pub get
```

### 4. Installer les dépendances du dashboard admin (optionnel)

```bash
cd admin-web/frontend/
npm install
```

---

## Configuration

### Backend — fichier `.env`

Le fichier `backend/.env` est déjà configuré et prêt à l'emploi.
La base de données MongoDB est hébergée dans le cloud (MongoDB Atlas), **aucune installation locale nécessaire**.

> Ne modifiez pas ce fichier sauf si vous avez votre propre MongoDB.

### App Mobile — URL du backend

Ouvrez le fichier `mobile-app/lib/config/api_config.dart` et choisissez selon votre situation :

```dart
// Si vous testez sur ÉMULATEUR Android
static const String baseUrl = 'http://10.0.2.2:5000/api';

// Si vous testez sur TÉLÉPHONE PHYSIQUE
// Remplacez par l'IP de votre ordinateur sur le réseau local
static const String baseUrl = 'http://192.168.1.XXX:5000/api';
```

**Comment trouver votre IP locale :**
```bash
# Linux / Mac
ip addr show | grep "inet 192"

# Windows
ipconfig
# Cherchez "Adresse IPv4"
```

---

## Démarrage

### Étape 1 — Démarrer le backend

```bash
cd backend/
npm run dev
```

**Sortie attendue :**
```
WaQti API
Serveur demarre sur le port 5000
Environnement: development
WebSocket: active
MongoDB connecte: waqti.pwhcmv0.mongodb.net
```

> Gardez ce terminal OUVERT pendant toute la durée des tests.
> Le code OTP de vérification s'affiche dans ce terminal.

### Étape 2 — Lancer l'app mobile

```bash
cd mobile-app/
flutter run
```

> Assurez-vous qu'un émulateur est ouvert avant de lancer cette commande,
> ou qu'un téléphone Android est connecté en USB avec le débogage USB activé.

### Étape 3 — Lancer le dashboard admin (optionnel)

```bash
cd admin-web/frontend/
npm run dev
```

Ouvrez http://localhost:5173 dans votre navigateur.

---

## Guide de test complet

---

### PARTIE 1 — GESTIONNAIRE

---

#### 1.1 — Créer un compte gestionnaire

1. Ouvrez l'app → écran de connexion
2. Appuyez sur **"Créer un compte"**
3. Remplissez le formulaire :
   - Nom : `Mohamed Gestionnaire`
   - Email : `gestionnaire@test.com`
   - Téléphone : `+22287654321`
   - Mot de passe : `123456`
4. Sélectionnez le rôle **Gestionnaire** (carte de droite)
5. Appuyez sur **"Créer mon compte"**
6. Regardez le terminal backend, vous verrez :
   ```
   [OTP] +22287654321: 847291
   ```
7. Saisissez ce code dans l'app
8. Vous êtes connecté — vous voyez **4 onglets** en bas (Recherche / Mes Tickets / Dashboard / Profil)

---

#### 1.2 — Enregistrer un établissement

1. Appuyez sur l'onglet **Dashboard** (icône tableau de bord)
2. Vous voyez "Aucun établissement" → appuyez **"Enregistrer mon établissement"**
3. Remplissez :
   - Nom : `Banque Nationale de Mauritanie`
   - Type : `Banque`
   - Rue/Quartier : `Rue du Port, Tevragh Zeina`
   - Ville : `Nouakchott`
   - Téléphone : `+22200001111`
4. Appuyez **"Soumettre pour validation"**
5. Écran de succès "Demande envoyée — En attente de validation"

---

#### 1.3 — Valider l'établissement (simulation admin via terminal)

Ouvrez un nouveau terminal et exécutez ces commandes une par une :

**Étape A — Se connecter pour obtenir un token :**
```bash
curl -X POST http://localhost:5000/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"identifier":"gestionnaire@test.com","motDePasse":"123456"}'
```
Notez le `userId` dans la réponse.

**Étape B — Vérifier l'OTP (regardez le terminal backend) :**
```bash
curl -X POST http://localhost:5000/api/auth/verify-otp \
  -H "Content-Type: application/json" \
  -d '{"userId":"COLLE_userId_ICI","code":"COLLE_OTP_ICI"}'
```
Notez le `accessToken` dans la réponse.

**Étape C — Promouvoir le compte en admin (dans MongoDB) :**
```bash
mongosh "mongodb+srv://waqti:hMg6nRWVqktzMQyr@waqti.pwhcmv0.mongodb.net/waqti" \
  --eval 'db.users.updateOne({email:"gestionnaire@test.com"},{$set:{role:"admin"}})'
```

**Étape D — Se reconnecter pour avoir un token admin (répéter A et B)**

**Étape E — Récupérer l'ID de l'établissement :**
```bash
curl -X GET "http://localhost:5000/api/admin/etablissements" \
  -H "Authorization: Bearer VOTRE_TOKEN_ADMIN"
```
Notez le `_id` de l'établissement.

**Étape F — Valider l'établissement :**
```bash
curl -X PATCH "http://localhost:5000/api/admin/etablissements/ETAB_ID_ICI/statut" \
  -H "Authorization: Bearer VOTRE_TOKEN_ADMIN" \
  -H "Content-Type: application/json" \
  -d '{"statut":"actif"}'
```

---

#### 1.4 — Créer un service dans l'établissement

```bash
curl -X POST "http://localhost:5000/api/etablissements/ETAB_ID_ICI/services" \
  -H "Authorization: Bearer VOTRE_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nom":"Caisse","description":"Depot et retrait","dureeEstimee":8}'
```

Notez le `_id` du service dans la réponse.

---

#### 1.5 — Voir le dashboard actif

1. Dans l'app gestionnaire → onglet **Dashboard**
2. Appuyez **"Vérifier le statut"** (ou tirez vers le bas pour rafraîchir)
3. Vous voyez maintenant le vrai dashboard :

```
┌──────────────────────────────────┐
│  En attente : 0  │  Traités : 0  │
├──────────────────────────────────┤
│  Ticket en cours : Aucun         │
├──────────────────────────────────┤
│    [ Appeler le suivant ]        │  ← grisé (file vide)
└──────────────────────────────────┘
File vide — aucun client en attente
```

---

### PARTIE 2 — CLIENT

---

#### 2.1 — Créer un compte client

1. Déconnectez-vous (onglet Profil → Déconnexion)
2. Appuyez **"Créer un compte"**
3. Remplissez :
   - Nom : `Ahmed Client`
   - Email : `client@test.com`
   - Téléphone : `+22212345678`
   - Mot de passe : `123456`
   - Rôle : **Client** (carte de gauche)
4. OTP depuis le terminal → saisissez-le
5. Connecté — vous voyez **3 onglets** : Recherche / Mes Tickets / Profil

---

#### 2.2 — Rechercher un établissement

1. Onglet **Recherche**
2. Appuyez sur le filtre **"Banque"** en haut
3. Vous voyez `Banque Nationale de Mauritanie`
4. Appuyez dessus → page détail avec services, horaires, avis

---

#### 2.3 — Prendre un ticket

1. Sur la page détail → section **Services** → appuyez **"Prendre ticket"** sur "Caisse"
2. Choisissez :
   - Mode : **A distance (depuis chez moi)**
   - Priorité : **Normal**
3. Appuyez **"Confirmer le ticket"**
4. Message de confirmation avec le numéro du ticket
5. Allez dans l'onglet **Mes Tickets**
6. Vous voyez votre ticket :

```
┌─────────────────────────────────────┐
│  WQ260318-0001              En attente│
├─────────────────────────────────────┤
│  Banque Nationale — Caisse          │
│                                     │
│  Position : 1    Attente : ~8 min   │
│                                     │
│  [Retard]          [Annuler]        │
└─────────────────────────────────────┘
```

---

#### 2.4 — Créer un 2ème client (pour tester la file)

Répétez les étapes 2.1 à 2.3 avec :
- Email : `client2@test.com`
- Téléphone : `+22211111111`

Ce client aura la position **2** avec **~16 min** d'attente.

---

### PARTIE 3 — TEST TEMPS RÉEL (CLÉ DE L'APPLICATION)

---

#### 3.1 — Appeler le suivant

> Pour ce test, il faut 2 émulateurs/téléphones OU utiliser un seul appareil en alternant les comptes.

**Sur l'appareil gestionnaire :**
1. Onglet Dashboard → `En attente : 2`
2. Appuyez **"Appeler le suivant"**
3. Popup : numéro et nom du client appelé

**Sur l'appareil client 1 (simultanément) :**
4. Une alerte apparaît automatiquement :
   ```
   C'est votre tour !
   Rendez-vous au guichet 1.
   ```

**Sur l'appareil client 2 :**
5. Position passe de **2** à **1** automatiquement

---

#### 3.2 — Appeler le suivant une 2ème fois

1. Gestionnaire appuie à nouveau sur **"Appeler le suivant"**
2. Client 2 reçoit : `"C'est votre tour ! Guichet 1"`
3. Dashboard gestionnaire → `En attente : 0`, file vide

---

### PARTIE 4 — FONCTIONNALITÉS SECONDAIRES

---

#### 4.1 — Signaler un retard

1. Client → onglet "Mes Tickets"
2. Appuyez **"Retard"** sur un ticket actif
3. Message : `"Retard signalé, votre place est conservée"`

---

#### 4.2 — Annuler un ticket

1. Client → onglet "Mes Tickets"
2. Appuyez **"Annuler"** → confirmez dans la popup
3. Le ticket disparaît de la liste
4. Sur le dashboard gestionnaire, le compteur diminue automatiquement

---

#### 4.3 — Profil utilisateur

1. Onglet **Profil**
2. Informations affichées : nom, email, téléphone, rôle
3. Bouton **Déconnexion** → retour à l'écran de login

---

### PARTIE 5 — DASHBOARD ADMIN WEB

---

1. Ouvrez http://localhost:5173
2. Connectez-vous avec le compte admin
3. Vous voyez le tableau de bord :
   - Statistiques globales (utilisateurs, établissements, tickets)
   - Graphique tickets par jour (7 derniers jours)
   - Top établissements par volume
4. Menu **Établissements** → liste complète avec statuts
5. Bouton pour changer le statut (actif / suspendu / en_attente)
6. Menu **Utilisateurs** → gestion avec filtres

---

## API Reference

> Base URL : `http://localhost:5000/api`
> Routes protégées : ajouter le header `Authorization: Bearer <token>`

### Authentification

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| POST | `/auth/register` | Inscription | Non |
| POST | `/auth/login` | Connexion | Non |
| POST | `/auth/verify-otp` | Vérifier OTP | Non |
| GET | `/auth/profile` | Mon profil | Oui |
| POST | `/auth/logout` | Déconnexion | Oui |
| GET | `/auth/my-etablissement` | Mon établissement | Oui |
| POST | `/auth/register-etablissement` | Créer établissement | Oui (gestionnaire) |

### Établissements

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| GET | `/etablissements` | Recherche (actifs uniquement) | Non |
| GET | `/etablissements/:id` | Détail | Non |
| GET | `/etablissements/:id/services` | Liste des services | Oui |
| POST | `/etablissements/:id/services` | Créer un service | Oui |
| GET | `/etablissements/:id/avis` | Avis et notes | Non |
| POST | `/etablissements/:id/avis` | Poster un avis | Oui |

### Tickets

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| GET | `/tickets/mes-tickets` | Mes tickets actifs | Oui |
| POST | `/tickets` | Créer un ticket | Oui |
| DELETE | `/tickets/:id/annuler` | Annuler | Oui |
| POST | `/tickets/:id/signaler-retard` | Signaler retard | Oui |

### File d'attente

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| GET | `/files/:serviceId` | Statut de la file | Oui |
| POST | `/files/:serviceId/appeler-suivant` | Appeler client suivant | Oui |

### Admin

| Méthode | Endpoint | Description | Auth |
|---------|----------|-------------|------|
| GET | `/admin/stats` | Statistiques globales | Admin |
| GET | `/admin/etablissements` | Tous les établissements | Admin |
| POST | `/admin/etablissements` | Créer (validé directement) | Admin |
| PATCH | `/admin/etablissements/:id/statut` | Changer statut | Admin |
| GET | `/admin/users` | Tous les utilisateurs | Admin |
| PATCH | `/admin/users/:id/statut` | Suspendre / activer | Admin |
| DELETE | `/admin/users/:id` | Supprimer utilisateur | Admin |

---

## Comptes de test

| Compte | Email | Téléphone | Mot de passe | Rôle |
|--------|-------|-----------|--------------|------|
| Client 1 | `client@test.com` | `+22212345678` | `123456` | client |
| Client 2 | `client2@test.com` | `+22211111111` | `123456` | client |
| Gestionnaire | `gestionnaire@test.com` | `+22287654321` | `123456` | gestionnaire |
| Admin | Promu via MongoDB | — | — | admin |

> Les OTP s'affichent dans la console du backend (terminal nodemon).
> En production, ils sont envoyés par SMS via Twilio.

---

## Structure des fichiers

```
waQti_App/
├── backend/                    <- API Node.js
│   ├── server.js               <- Point d'entrée
│   ├── .env                    <- Configuration
│   ├── src/
│   │   ├── controllers/        <- Logique métier
│   │   ├── models/             <- Schémas MongoDB
│   │   ├── routes/             <- Endpoints API
│   │   ├── middleware/         <- Auth JWT, rate limiting
│   │   ├── sockets/            <- WebSocket temps réel
│   │   └── utils/              <- OTP, SMS, QR code
│   └── package.json
│
├── mobile-app/                 <- App Flutter
│   ├── lib/
│   │   ├── main.dart           <- Point d'entrée
│   │   ├── config/             <- URL API, thème couleurs
│   │   ├── models/             <- Modèles de données
│   │   ├── providers/          <- État global (auth)
│   │   ├── services/           <- HTTP (Dio) + WebSocket
│   │   └── screens/
│   │       ├── auth/           <- Login, Register, OTP
│   │       ├── home/           <- Navigation principale
│   │       ├── search/         <- Recherche établissements
│   │       ├── ticket/         <- Créer et suivre tickets
│   │       ├── etablissement/  <- Dashboard gestionnaire
│   │       └── profile/        <- Profil utilisateur
│   └── pubspec.yaml
│
└── admin-web/frontend/         <- Dashboard React
    ├── src/
    │   ├── pages/              <- Dashboard, Etablissements, Users
    │   ├── components/         <- Layout, StatCard, DataTable
    │   └── services/           <- API Axios
    └── package.json
```

---

## Problèmes fréquents

### "MongoDB erreur: querySrv ECONNREFUSED"
Le backend ne peut pas résoudre le DNS MongoDB.

Solution : vérifier que le script dans `backend/package.json` contient :
```json
"dev": "NODE_OPTIONS=--dns-result-order=ipv4first nodemon server.js"
```

---

### "Connection refused" dans l'app mobile
L'app ne trouve pas le backend.

Solution : vérifier l'URL dans `mobile-app/lib/config/api_config.dart`
- Émulateur Android → `http://10.0.2.2:5000/api`
- Téléphone physique → `http://192.168.X.X:5000/api` (votre IP locale)
- Ne jamais utiliser `localhost` sur téléphone physique

---

### Le code OTP n'arrive pas par SMS
Normal en développement. L'OTP s'affiche dans le terminal backend :
```
[OTP] +222XXXXXXXX: 123456
```

---

### "Seuls les gestionnaires peuvent enregistrer un établissement"
Vous êtes connecté avec un compte `client`.
Solution : utiliser un compte avec `role: "gestionnaire"`.

---

### L'établissement n'apparaît pas dans la recherche
L'établissement est encore `en_attente`.
Solution : le valider via l'API admin (voir section 1.3 du guide de test).

---

### flutter pub get échoue
```bash
flutter clean
flutter pub get
```

---

## Technologies utilisées

| Technologie | Version | Usage |
|-------------|---------|-------|
| Flutter | 3.2+ | App mobile Android |
| Dart | 3.2+ | Langage Flutter |
| Node.js | 18+ | Serveur backend |
| Express | 4.22 | Framework API REST |
| MongoDB Atlas | 8.0 | Base de données cloud |
| Mongoose | 8.23 | ORM MongoDB |
| Socket.io | 4.8 | Temps réel WebSocket |
| Twilio | 5.13 | Envoi SMS OTP |
| JWT | 9.0 | Authentification tokens |
| React | 18 | Dashboard admin web |
| Vite | 5 | Build tool React |

---

*WaQti v1.0.0 — Mauritanie*
