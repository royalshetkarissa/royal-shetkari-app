const jwt = require('jsonwebtoken');
const env = require('../config/env');

/**
 * Sign a new access token (short-lived).
 */
exports.signAccessToken = (payload) => {
  return jwt.sign(payload, env.JWT_SECRET, {
    expiresIn: '1h', // 1 hour for secure session management
  });
};

/**
 * Verify a JWT token.
 */
exports.verifyToken = (token) => {
  return jwt.verify(token, env.JWT_SECRET);
};
