const { Pool } = require('pg');
const env = require('./env');
const logger = require('../utils/logger');

const databaseUrl = process.env.DATABASE_URL || env.DATABASE_URL;
const isProd = env.NODE_ENV === 'production';

let poolConfig;

if (
  databaseUrl &&
  databaseUrl !== '/' &&
  databaseUrl !== 'localhost' &&
  databaseUrl !== '127.0.0.1'
) {
  poolConfig = {
    connectionString: databaseUrl,
    ssl: isProd ? { rejectUnauthorized: env.DB_SSL_REJECT_UNAUTHORIZED } : false,
    max: 50,
    min: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
    query_timeout: 30000,
  };
} else {
  const host = env.DB.HOST || '127.0.0.1';
  const safeHost =
    (host === '/' || host === 'localhost' || host === '127.0.0.1') && isProd ? undefined : host;

  if (isProd && !safeHost) {
    logger.error('💥 Critical: No valid DATABASE_URL or database host configured for production.');
    process.exit(1);
  }

  poolConfig = {
    user: env.DB.USER,
    password: env.DB.PASSWORD,
    host: safeHost,
    port: env.DB.PORT,
    database: env.DB.NAME,
    max: 50,
    min: 10,
    idleTimeoutMillis: 30000,
    connectionTimeoutMillis: 5000,
    query_timeout: 30000,
  };
}

const pool = new Pool(poolConfig);

/**
 * Connects to the database with exponential backoff retry logic.
 */
const connectWithRetry = async (attempt = 1) => {
  const maxAttempts = 10;
  const delay = Math.min(Math.pow(2, attempt) * 1000, 30000);

  try {
    const client = await pool.connect();
    logger.info('✅ PostgreSQL connected successfully');
    client.release();
  } catch (err) {
    if (attempt <= maxAttempts) {
      logger.warn(
        `❌ DB connection failed (Attempt ${attempt}/${maxAttempts}). Retrying in ${delay / 1000}s...`,
        { error: err.message }
      );
      setTimeout(() => connectWithRetry(attempt + 1), delay);
    } else {
      logger.error('💥 Critical: Could not connect to PostgreSQL after multiple attempts.', {
        error: err.message,
      });
      process.exit(1);
    }
  }
};

/**
 * Wrapper for pool.query with automatic retry logic.
 * 3 attempts with exponential backoff.
 */
pool.queryWithRetry = async (text, params, attempt = 1) => {
  const maxAttempts = 3;
  const delay = Math.pow(2, attempt) * 100; // 200ms, 400ms, 800ms

  try {
    return await pool.query(text, params);
  } catch (err) {
    // Retry on connection errors or transient issues (standard pg error codes)
    const retryableErrors = ['08000', '08003', '08006', '57P01', '57P02', '57P03'];
    if (
      attempt < maxAttempts &&
      (retryableErrors.includes(err.code) || err.message.includes('timeout'))
    ) {
      logger.warn(
        `Retrying query (Attempt ${attempt}/${maxAttempts}) due to error: ${err.message}`
      );
      await new Promise((resolve) => setTimeout(resolve, delay));
      return pool.queryWithRetry(text, params, attempt + 1);
    }
    throw err;
  }
};

pool.on('error', (err) => {
  logger.error('❌ Unexpected error on idle DB client', { error: err.message });
});

if (env.NODE_ENV !== 'test') {
  connectWithRetry();
}

module.exports = pool;
