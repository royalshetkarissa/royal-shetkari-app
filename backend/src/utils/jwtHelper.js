const jwt = require('jsonwebtoken');
const env = require('../config/env');

/**
 * Sign a new access token (short-lived).
 */
exports.signAccessToken = (payload) => {
  return jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: '7d', // 7 days for a seamless mobile/web session experience
  });
};

/**
 * Verify a JWT token.
 */
exports.verifyToken = (token) => {
  return jwt.verify(token, env.JWT_SECRET);
};
