const mongoose = require('mongoose');

const connectDB = async () => {
  try {
    const conn = await mongoose.connect(process.env.MONGODB_URI, { dbName: 'waqti' });
    console.log('  MongoDB connecte: ' + conn.connection.host);
    // Supprimer l'ancien index email s'il existe
    try {
      await conn.connection.db.collection('users').dropIndex('email_1');
      console.log('  Index email_1 supprimé');
    } catch (_) {}
  } catch (error) {
    console.error('  MongoDB erreur: ' + error.message);
    process.exit(1);
  }
};

module.exports = connectDB;
