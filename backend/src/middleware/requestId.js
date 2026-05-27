const crypto = require('crypto');

/**
 * Middleware to attach a unique request ID to each request.
 */
const requestId = (req, res, next) => {
  req.id = crypto.randomUUID();
  res.setHeader('X-Request-Id', req.id);
  next();
};

module.exports = requestId;
