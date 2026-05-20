const { connection: redis } = require('../config/redis');
const logger = require('./logger');

/**
 * Utility for O(1) Redis Caching.
 */
class Cache {
  constructor() {
    this.redis = redis;
  }

  async get(key) {
    try {
      const data = await this.redis.get(key);
      return data ? JSON.parse(data) : null;
    } catch (err) {
      logger.error(`Cache GET error for key ${key}:`, err);
      return null;
    }
  }

  async set(key, value, ttl = 300) {
    try {
      await this.redis.set(key, JSON.stringify(value), 'EX', ttl);
    } catch (err) {
      logger.error(`Cache SET error for key ${key}:`, err);
    }
  }

  async del(key) {
    try {
      await this.redis.del(key);
    } catch (err) {
      logger.error(`Cache DEL error for key ${key}:`, err);
    }
  }

  async invalidatePattern(pattern) {
    try {
      const keys = await this.redis.keys(pattern);
      if (keys.length > 0) {
        await this.redis.del(...keys);
        logger.info(`Invalidated ${keys.length} cache keys matching ${pattern}`);
      }
    } catch (err) {
      logger.error(`Cache invalidation error for pattern ${pattern}:`, err);
    }
  }
}

module.exports = new Cache();
