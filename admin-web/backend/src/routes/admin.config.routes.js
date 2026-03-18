const router = require('express').Router();

router.get('/', (req, res) => {
  res.json({ success: true, message: 'Route admin.config - A implementer' });
});

module.exports = router;
