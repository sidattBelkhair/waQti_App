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
