# WaQti - API Endpoints complets

Base URL : `http://<host>:5000/api`

---

## AUTH

| Méthode | Endpoint | Auth requise | Rôle | Description |
|---------|----------|:---:|------|-------------|
| POST | `/auth/register` | Non | Tous | Inscription (client ou gestionnaire). Envoie OTP SMS. Retourne `userId`. En dev : `devOtp`. |
| POST | `/auth/login` | Non | Tous | Connexion avec email/téléphone + mot de passe. Envoie OTP SMS. Retourne `userId`. En dev : `devOtp`. |
| POST | `/auth/verify-otp` | Non | Tous | Vérifier le code OTP reçu par SMS. Retourne `accessToken` + `refreshToken` + `user`. |
| POST | `/auth/refresh-token` | Non | Tous | Renouveler l'access token avec un refresh token valide. |
| POST | `/auth/logout` | Oui | Tous | Déconnexion — invalide le refresh token. |
| GET | `/auth/profile` | Oui | Tous | Voir son profil (nom, email, téléphone, rôle, photo). |
| PUT | `/auth/profile` | Oui | Tous | Modifier son profil (nom, photo, nni). |
| POST | `/auth/change-phone` | Oui | Tous | Initier changement de téléphone — envoie OTP au nouveau numéro. |
| POST | `/auth/forgot-password` | Non | Tous | Demander réinitialisation MDP via téléphone. Envoie token par SMS. En dev : `devToken` (8 chars). |
| POST | `/auth/reset-password` | Non | Tous | Réinitialiser le MDP avec le token SMS (8 chars) ou token complet. |
| POST | `/auth/register-etablissement` | Oui | gestionnaire | Créer un établissement lié au gestionnaire connecté. Statut initial : `en_attente`. |
| GET | `/auth/my-etablissement` | Oui | gestionnaire | Récupérer l'établissement du gestionnaire connecté. |

**Corps register :**
```json
{ "nom": "string", "email": "string", "telephone": "+222XXXXXXXX", "motDePasse": "string", "role": "client|gestionnaire" }
```

**Corps login :**
```json
{ "identifier": "email ou téléphone", "motDePasse": "string" }
```

**Corps verify-otp :**
```json
{ "userId": "string", "code": "6 chiffres" }
```

**Corps forgot-password :**
```json
{ "telephone": "+222XXXXXXXX" }
```

**Corps reset-password :**
```json
{ "token": "8 chars (SMS) ou token complet", "newPassword": "string" }
```

---

## ÉTABLISSEMENTS

| Méthode | Endpoint | Auth requise | Rôle | Description |
|---------|----------|:---:|------|-------------|
| GET | `/etablissements` | Non | Tous | Recherche avec filtres (nom, type, ville, lat, lng). Tri par distance si lat/lng fourni. |
| GET | `/etablissements/:id` | Non | Tous | Détails d'un établissement (services inclus). |
| PUT | `/etablissements/:id` | Oui | gestionnaire / admin | Modifier nom, adresse, horaires, contact, etc. |
| DELETE | `/etablissements/:id` | Oui | admin | Supprimer un établissement. |
| POST | `/etablissements/:id/fermetures` | Oui | gestionnaire | Ajouter une fermeture exceptionnelle (date + motif). |
| GET | `/etablissements/:id/services` | Non | Tous | Liste des services de l'établissement. |
| POST | `/etablissements/:id/services` | Oui | gestionnaire | Créer un nouveau service. |
| PUT | `/etablissements/:id/services/:sid` | Oui | gestionnaire | Modifier un service (nom, durée, guichets, etc.). |
| DELETE | `/etablissements/:id/services/:sid` | Oui | gestionnaire | Supprimer un service. |
| GET | `/etablissements/:id/personnel` | Oui | gestionnaire | Liste des agents rattachés à l'établissement. |
| POST | `/etablissements/:id/personnel` | Oui | gestionnaire | Ajouter un agent (userId existant). |
| PUT | `/etablissements/:id/personnel/:aid/disponibilites` | Oui | gestionnaire | Définir les disponibilités d'un agent. |
| POST | `/etablissements/:id/personnel/:aid/conges` | Oui | gestionnaire | Déclarer un congé pour un agent. |
| POST | `/etablissements/:id/avis` | Oui | client | Déposer un avis (note 1–5 + commentaire + ticketId). |
| GET | `/etablissements/:id/avis` | Non | Tous | Liste des avis d'un établissement. |

**Paramètres GET /etablissements :**
```
?nom=banque&type=banque&ville=Nouakchott&lat=18.079&lng=-15.965
```

**Corps POST /etablissements/:id/services :**
```json
{ "nom": "string", "description": "string", "dureeEstimee": 10, "maxParJour": 100, "guichets": 2 }
```

---

## TICKETS

| Méthode | Endpoint | Auth requise | Rôle | Description |
|---------|----------|:---:|------|-------------|
| POST | `/tickets` | Oui | client | Créer un ticket (file d'attente immédiate). |
| POST | `/tickets/rdv` | Oui | client | Créer un ticket RDV (date + créneau horaire). |
| GET | `/tickets/mes-tickets` | Oui | client | Liste des tickets du client connecté. |
| GET | `/tickets/etablissement` | Oui | gestionnaire | Liste des tickets de l'établissement du gestionnaire. |
| DELETE | `/tickets/:id/annuler` | Oui | client | Annuler un ticket (si statut = `en_attente`). |
| POST | `/tickets/:id/signaler-retard` | Oui | client | Signaler un retard sur un ticket RDV. |
| POST | `/tickets/:id/valider-presence` | Oui | gestionnaire | Valider la présence du client (scan QR par ID). |
| POST | `/tickets/scan/:numero/valider` | Oui | gestionnaire | Valider la présence par numéro de ticket (QR code simple, ex: `WQ-240001`). |

**Corps POST /tickets :**
```json
{ "etablissementId": "string", "serviceId": "string", "mode": "presentiel|distance", "priorite": 0 }
```

**Corps POST /tickets/rdv :**
```json
{ "etablissementId": "string", "serviceId": "string", "date": "2026-03-25", "creneau": "09:00" }
```

**Statuts ticket :** `en_attente` → `en_cours` → `termine` / `annule` / `absent`

**Format numéro ticket :** `WQ-YYMMDD-XXXX` (ex: `WQ-260325-0001`)

---

## FILES D'ATTENTE

| Méthode | Endpoint | Auth requise | Rôle | Description |
|---------|----------|:---:|------|-------------|
| GET | `/files/:serviceId` | Non | Tous | État complet de la file (tickets en attente, en cours, temps estimé). |
| GET | `/files/:serviceId/position` | Oui | client | Position du client dans la file pour ce service. |
| POST | `/files/:serviceId/appeler-suivant` | Oui | gestionnaire | Appeler le prochain client à un guichet donné. |
| POST | `/files/:serviceId/absent` | Oui | gestionnaire | Marquer le client actuel comme absent. |

**Corps POST /files/:serviceId/appeler-suivant :**
```json
{ "guichet": 1 }
```

**Réponse GET /files/:serviceId :**
```json
{
  "file": {
    "serviceId": "...",
    "enAttente": 12,
    "enCours": 2,
    "tempsEstimeMinutes": 60,
    "dernierNumero": "WQ-260325-0014"
  }
}
```

---

## ADMIN

| Méthode | Endpoint | Auth requise | Rôle | Description |
|---------|----------|:---:|------|-------------|
| GET | `/admin/etablissements` | Oui | admin | Liste tous les établissements (tous statuts). |
| PATCH | `/admin/etablissements/:id/statut` | Oui | admin | Changer le statut d'un établissement (`actif`, `suspendu`, `en_attente`). |
| DELETE | `/admin/etablissements/:id` | Oui | admin | Supprimer définitivement un établissement. |
| GET | `/admin/users` | Oui | admin | Liste tous les utilisateurs. |
| PATCH | `/admin/users/:id/statut` | Oui | admin | Suspendre ou réactiver un utilisateur. |
| GET | `/admin/stats` | Oui | admin | Statistiques globales (nb users, établissements, tickets, etc.). |

**Créer un admin en MongoDB (Atlas) :**
```js
db.users.insertOne({
  nom: "Admin WaQti",
  email: "admin@waqti.mr",
  telephone: "+22200000000",
  motDePasse: require('bcryptjs').hashSync("admin1234", 12),
  role: "admin",
  statut: "actif",
  refreshTokens: [],
  createdAt: new Date()
})
```

---

## WEBSOCKET (Socket.IO)

Connexion : `ws://<host>:5000`

| Événement (émis par client) | Description |
|-----------------------------|-------------|
| `join_service` | Rejoindre la room d'un service : `{ serviceId }` |
| `leave_service` | Quitter la room d'un service |

| Événement (reçu par client) | Description |
|-----------------------------|-------------|
| `file_updated` | File mise à jour (appel suivant, annulation, absence) : `{ serviceId, enAttente, enCours }` |
| `ticket_called` | Client appelé au guichet : `{ ticketId, guichet, numero }` |
| `ticket_absent` | Client marqué absent |

---

## CODES D'ERREUR HTTP

| Code | Signification |
|------|--------------|
| 400 | Requête invalide (champ manquant, OTP expiré, token invalide) |
| 401 | Non authentifié (token absent ou expiré) |
| 403 | Accès interdit (rôle insuffisant, compte suspendu) |
| 404 | Ressource introuvable |
| 429 | Trop de tentatives (rate limit OTP : 3 essais max) |
| 500 | Erreur serveur interne |

---

## TYPES D'ÉTABLISSEMENTS (domaines)

| Valeur | Libellé |
|--------|---------|
| `hopital` | Hôpital / Clinique |
| `banque` | Banque |
| `administration` | Administration publique |
| `poste` | Bureau de poste |
| `telecom` | Télécommunications |
| `assurance` | Assurance |
| `ambassade` | Ambassade / Consulat |
| `universite` | Université / École |
| `autre` | Autre |

---

## PRIORITÉS TICKET

| Valeur | Description |
|--------|-------------|
| `0` | Normal |
| `1` | Prioritaire (personne âgée, femme enceinte) |
| `2` | Urgence |

---

## NOTES DE DÉVELOPPEMENT

- **devOtp** : retourné dans `/auth/login` et `/auth/register` quand `NODE_ENV !== 'production'`. S'affiche sur l'écran OTP.
- **devToken** : retourné dans `/auth/forgot-password` quand `NODE_ENV !== 'production'`. S'affiche sur l'écran reset-password.
- **QR code** : contient uniquement le numéro du ticket (ex: `WQ-260325-0001`). Le scanner appelle `POST /tickets/scan/:numero/valider`.
- **Tokens JWT** : access token (15 min), refresh token (30 jours). Rotation automatique via intercepteur Dio.
