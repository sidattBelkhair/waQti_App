const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const mongoose = require('mongoose');
require('dotenv').config();

const app = express();
app.use(cors());
app.use(helmet());
app.use(morgan('dev'));
app.use(express.json());

mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/waqti')
  .then(() => console.log('[Admin] MongoDB connecte'))
  .catch(err => console.error('[Admin] MongoDB erreur:', err.message));

app.use('/api/admin/etablissements', require('./src/routes/admin.etablissements.routes'));
app.use('/api/admin/users', require('./src/routes/admin.users.routes'));
app.use('/api/admin/stats', require('./src/routes/admin.stats.routes'));
app.use('/api/admin/config', require('./src/routes/admin.config.routes'));

app.get('/api/admin/health', (req, res) => {
  res.json({ status: 'OK', app: 'WaQti Admin API' });
});

const PORT = process.env.ADMIN_PORT || 5001;
app.listen(PORT, () => { console.log('[Admin] Serveur demarre sur le port ' + PORT); });
