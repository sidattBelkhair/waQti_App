const router = require('express').Router();

router.get('/', (req, res) => {
  res.json({ success: true, message: 'Route admin.users - A implementer' });
});

module.exports = router;
