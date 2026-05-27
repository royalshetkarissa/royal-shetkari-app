const IORedis = require('ioredis');
const logger = require('../utils/logger');

const env = require('./env');

const isProd = env.NODE_ENV === 'production';
const rawRedisUrl = process.env.REDIS_URL;

// Sanitize REDIS_URL to ignore dummy/placeholder/local socket values in production
const isValidUrl = (url) => {
  if (!url) return false;
  const trimmed = url.trim();
  if (trimmed === '' || trimmed === '/' || trimmed === 'localhost' || trimmed === '127.0.0.1') {
    return false;
  }
  // Check if it starts with redis:// or rediss://
  return trimmed.startsWith('redis://') || trimmed.startsWith('rediss://');
};

const redisConfig = {
  maxRetriesPerRequest: null, // Required by BullMQ
  enableOfflineQueue: true, // Allow queueing commands while offline to prevent immediate crashes
  retryStrategy: (times) => {
    // Exponential backoff cap to prevent CPU-spinning infinite reconnect loop
    const maxDelay = 10000; // 10 seconds max delay
    const delay = Math.min(times * 100, maxDelay);
    logger.warn(`Redis connection retry attempt #${times}. Next retry in ${delay}ms`);
    return delay;
  },
  reconnectOnError: (err) => {
    logger.warn('Redis reconnecting on error:', { error: err.message });
    return true;
  },
};

let connection;

if (isValidUrl(rawRedisUrl)) {
  try {
    logger.info('Initializing Redis client with REDIS_URL...');
    connection = new IORedis(rawRedisUrl, redisConfig);
  } catch (err) {
    logger.error('Failed to initialize Redis using REDIS_URL:', { error: err.message });
  }
} else {
  // If invalid or absent REDIS_URL, check for host/port/password
  const host = process.env.REDIS_HOST;
  const port = parseInt(process.env.REDIS_PORT) || 6379;
  const password = process.env.REDIS_PASSWORD || undefined;

  const isHostValid = host && host !== '/' && host !== 'localhost' && host !== '127.0.0.1';

  if (isProd && !isHostValid) {
    logger.warn(
      '⚠️ No valid production Redis URL or Host configured. Initializing Redis client in offline/lazy mode.'
    );
    connection = new IORedis({
      lazyConnect: true, // Don't try to connect automatically
      ...redisConfig,
    });
  } else {
    logger.info(`Initializing Redis client with host: ${host || 'localhost'}, port: ${port}...`);
    connection = new IORedis({
      host: host || 'localhost',
      port,
      password,
      ...redisConfig,
    });
  }
}

connection.on('connect', () => {
  logger.info('✅ Redis connected successfully');
});

connection.on('error', (err) => {
  logger.error('❌ Redis connection error:', { error: err.message });
});

module.exports = {
  connection,
  redisConfig,
};
