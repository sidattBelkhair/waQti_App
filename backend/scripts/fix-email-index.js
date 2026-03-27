require('dotenv').config();
const mongoose = require('mongoose');

(async () => {
  await mongoose.connect(process.env.MONGODB_URI);
  const db = mongoose.connection.db;
  const col = db.collection('users');

  try {
    await col.dropIndex('email_1');
    console.log('✅ Ancien index email_1 supprimé');
  } catch (e) {
    console.log('ℹ️  Index email_1 inexistant ou déjà supprimé');
  }

  await col.createIndex({ email: 1 }, { unique: true, sparse: true });
  console.log('✅ Nouvel index email sparse créé');
  await mongoose.disconnect();
})();
