module.exports = {
  accessTokenSecret: process.env.JWT_ACCESS_SECRET || 'waqti_dev_access',
  refreshTokenSecret: process.env.JWT_REFRESH_SECRET || 'waqti_dev_refresh',
  accessTokenExpiry: '1h',
  refreshTokenExpiry: '30d',
  saltRounds: 12,
};
