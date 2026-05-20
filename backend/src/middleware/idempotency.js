const { connection: redis } = require('../config/redis');
const logger = require('../utils/logger');

/**
 * Middleware to handle Idempotency-Key headers.
 * Prevents duplicate processing of critical transactions.
 */
const idempotency = (ttl = 86400) => async (req, res, next) => {
  const key = req.headers['idempotency-key'];

  if (!key) {
    return next();
  }

  const redisKey = `idempotency:${key}`;

  try {
    // 1. Check if key exists
    const cachedResponse = await redis.get(redisKey);
    if (cachedResponse) {
      logger.info(`Idempotency hit for key: ${key}`);
      const { status, body } = JSON.parse(cachedResponse);
      return res.status(status).json(body);
    }

    // 2. Wrap res.json to cache the result
    const originalJson = res.json;
    res.json = function (body) {
      // Only cache successful or non-server-error responses
      if (res.statusCode >= 200 && res.statusCode < 500) {
        redis.set(redisKey, JSON.stringify({
          status: res.statusCode,
          body
        }), 'EX', ttl).catch(err => logger.error('Failed to cache idempotency key', err));
      }
      return originalJson.call(this, body);
    };

    next();
  } catch (err) {
    logger.error('Idempotency middleware error', err);
    next(); // Continue anyway to not block the user
  }
};

module.exports = idempotency;
