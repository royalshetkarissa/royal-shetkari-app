const IORedis = require('ioredis');
const logger = require('../utils/logger');

const redisConfig = process.env.REDIS_URL ? {
  maxRetriesPerRequest: null, // Required by BullMQ
  retryStrategy: (times) => {
    // Exponential backoff
    return Math.min(times * 50, 2000);
  }
} : {
  host: process.env.REDIS_HOST || 'localhost',
  port: parseInt(process.env.REDIS_PORT) || 6379,
  password: process.env.REDIS_PASSWORD || undefined,
  maxRetriesPerRequest: null, // Required by BullMQ
  retryStrategy: (times) => {
    // Exponential backoff
    return Math.min(times * 50, 2000);
  }
};

const connection = process.env.REDIS_URL 
  ? new IORedis(process.env.REDIS_URL, redisConfig)
  : new IORedis(redisConfig);

connection.on('connect', () => {
  logger.info('✅ Redis Cloud connected successfully');
});

connection.on('error', (err) => {
  logger.error('❌ Redis connection error:', { error: err.message });
});

module.exports = {
  connection,
  redisConfig
};
