const express = require('express');
const http = require('http');
const { Server } = require('socket.io');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const connectDB = require('./src/config/database');
const errorHandler = require('./src/middleware/errorHandler');
const { initTwilio } = require('./src/utils/sms');
require('dotenv').config();

const app = express();
const server = http.createServer(app);
const io = new Server(server, {
  cors: {
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE'],
  },
});

// Middleware globaux
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true }));

// Connexion MongoDB
connectDB();
initTwilio();

// Routes API
app.use('/api/auth', require('./src/routes/auth.routes'));
app.use('/api/etablissements', require('./src/routes/etablissement.routes'));
app.use('/api/services', require('./src/routes/etablissement.routes'));
app.use('/api/tickets', require('./src/routes/ticket.routes'));
app.use('/api/files', require('./src/routes/file.routes'));
app.use('/api/admin', require('./src/routes/admin.routes'));

// WebSocket - Files d'attente temps reel
const fileQueueSocket = require('./src/sockets/fileQueue.socket');
fileQueueSocket(io);
app.set('io', io);

// Route seed (dev uniquement)
app.post('/api/seed', async (req, res) => {
  if (process.env.NODE_ENV !== 'development') return res.status(403).json({ error: 'Non autorisé' });
  try {
    const User = require('./src/models/User');
    const Etablissement = require('./src/models/Etablissement');
    const Service = require('./src/models/Service');

    const testEmails = ['admin@waqti.mr', 'gestionnaire@waqti.mr', 'client@waqti.mr'];
    await User.deleteMany({ email: { $in: testEmails } });

    const users = [
      { nom: 'Admin WaQti',           email: 'admin@waqti.mr',        telephone: '+22200000001', motDePasse: 'Admin@1234',  role: 'admin',        statut: 'actif' },
      { nom: 'Sidatte Gestionnaire',  email: 'gestionnaire@waqti.mr', telephone: '+22200000002', motDePasse: 'Gest@1234',   role: 'gestionnaire', statut: 'actif' },
      { nom: 'Sidatte Client',        email: 'client@waqti.mr',       telephone: '+22200000003', motDePasse: 'Client@1234', role: 'client',       statut: 'actif' },
    ];

    const created = [];
    for (const u of users) {
      const doc = new User(u);
      await doc.save();
      created.push(doc);
    }

    const gestionnaire = created.find(u => u.role === 'gestionnaire');
    await Etablissement.deleteMany({ email: 'hopital-zayed@seed.mr' });
    const etab = await Etablissement.create({
      nom: 'Hôpital Zayed', type: 'hopital',
      adresse: { rue: 'Rue Abdallahi Ould Daddah', ville: 'Nouakchott' },
      telephone: '+22245000001', email: 'hopital-zayed@seed.mr',
      responsable: gestionnaire._id, statut: 'actif',
    });
    await Service.deleteMany({ etablissement: etab._id });
    await Service.insertMany([
      { nom: 'Consultation générale', etablissement: etab._id },
      { nom: 'Urgences',              etablissement: etab._id },
      { nom: 'Radiologie',            etablissement: etab._id },
      { nom: 'Pédiatrie',             etablissement: etab._id },
    ]);

    res.json({ success: true, message: 'Données de test créées', users: users.map(u => ({ role: u.role, email: u.email, telephone: u.telephone, motDePasse: u.motDePasse })) });
  } catch (err) {
    res.status(500).json({ success: false, error: err.message });
  }
});

// Route de sante
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    app: 'WaQti API',
    version: '1.0.0',
    timestamp: new Date().toISOString(),
    uptime: process.uptime(),
  });
});

// 404
app.use('*', (req, res) => {
  res.status(404).json({ success: false, error: 'Route ' + req.originalUrl + ' non trouvee' });
});

// Gestion erreurs
app.use(errorHandler);

// Demarrage
const PORT = process.env.PORT || 5000;
server.listen(PORT, () => {
  console.log('');
  console.log('  WaQti API');
  console.log('  Serveur demarre sur le port ' + PORT);
  console.log('  Environnement: ' + (process.env.NODE_ENV || 'development'));
  console.log('  WebSocket: active');
  console.log('');
});

module.exports = { app, server, io };
