# WaQti - API Endpoints

## Auth
| Methode | Endpoint | Description |
|---------|----------|-------------|
| POST | /api/auth/register | Inscription client |
| POST | /api/auth/login | Connexion (envoie OTP) |
| POST | /api/auth/verify-otp | Verifier code OTP |
| POST | /api/auth/refresh-token | Renouveler access token |
| POST | /api/auth/logout | Deconnexion |
| GET | /api/auth/profile | Voir profil |
| PUT | /api/auth/profile | Modifier profil |
| POST | /api/auth/change-phone | Changer telephone |
| POST | /api/auth/forgot-password | Mot de passe oublie |
| POST | /api/auth/reset-password | Reinitialiser MDP |
| POST | /api/auth/register-etablissement | Inscrire etablissement |

## Etablissements
| Methode | Endpoint | Description |
|---------|----------|-------------|
| GET | /api/etablissements | Recherche avec filtres |
| GET | /api/etablissements/:id | Fiche etablissement |
| PUT | /api/etablissements/:id | Modifier etablissement |
| POST | /api/etablissements/:id/fermetures | Ajouter fermeture |
| GET | /api/etablissements/:id/services | Liste services |
| POST | /api/etablissements/:id/services | Creer service |
| PUT | /api/etablissements/:id/services/:sid | Modifier service |
| DELETE | /api/etablissements/:id/services/:sid | Supprimer service |
| POST | /api/services/:sid/guichets | Ajouter guichet |
| GET | /api/etablissements/:id/personnel | Liste personnel |
| POST | /api/etablissements/:id/personnel | Ajouter agent |
| PUT | /api/etablissements/:id/personnel/:aid/disponibilites | Disponibilites |
| POST | /api/etablissements/:id/personnel/:aid/conges | Declarer conge |
| POST | /api/etablissements/:id/avis | Deposer avis |
| GET | /api/etablissements/:id/avis | Liste avis |

## Tickets
| Methode | Endpoint | Description |
|---------|----------|-------------|
| POST | /api/tickets | Creer ticket |
| POST | /api/tickets/rdv | Creer ticket RDV |
| DELETE | /api/tickets/:id/annuler | Annuler ticket |
| POST | /api/tickets/:id/signaler-retard | Signaler retard |
| POST | /api/tickets/:id/valider-presence | Scanner QR |

## Files d attente
| Methode | Endpoint | Description |
|---------|----------|-------------|
| GET | /api/files/:serviceId | Etat de la file |
| GET | /api/files/:serviceId/position | Position du client |
| POST | /api/files/:serviceId/appeler-suivant | Appeler suivant |

## Admin
| Methode | Endpoint | Description |
|---------|----------|-------------|
| GET | /api/admin/etablissements | Liste etablissements |
| PATCH | /api/admin/etablissements/:id/statut | Changer statut |
| GET | /api/admin/users | Liste utilisateurs |
| PATCH | /api/admin/users/:id/statut | Suspendre/reactiver |
| GET | /api/admin/stats | Stats globales |
