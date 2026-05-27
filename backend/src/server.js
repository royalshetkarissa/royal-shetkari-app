const app = require('./app');
const env = require('./config/env');
const pool = require('./config/db');
const { connection: redis } = require('./config/redis');
const logger = require('./utils/logger');
const migrationRunner = require('./utils/migrationRunner');

const PORT = env.PORT || 5000;

// Start Background Worker
require('./jobs/postWorker');

const server = app.listen(PORT, async () => {
  logger.info(`🚀 Production Server running on port ${PORT}`);

  // Run Database Migrations and Bootstrap Admin
  try {
    await migrationRunner.up();
    const bootstrapAdmin = require('./utils/bootstrapAdmin');
    await bootstrapAdmin();
  } catch (err) {
    logger.error('Failed to run migrations or bootstrap on startup', err);
  }
});

/**
 * Handle Unhandled Rejections (Async)
 */
process.on('unhandledRejection', (err) => {
  logger.error('💥 UNHANDLED REJECTION! Shutting down...', {
    error: err.message,
    stack: err.stack,
  });
  server.close(() => {
    process.exit(1);
  });
});

/**
 * Handle Uncaught Exceptions (Sync)
 */
process.on('uncaughtException', (err) => {
  logger.error('💥 UNCAUGHT EXCEPTION! Shutting down...', { error: err.message, stack: err.stack });
  process.exit(1);
});

/**
 * Graceful Shutdown Handler
 */
const gracefulShutdown = (signal) => {
  logger.info(`\n🛑 ${signal} received. Starting graceful shutdown...`);

  // 1. Stop accepting new connections
  server.close(async () => {
    logger.info('HTTP server closed. Cleaning up resources...');

    try {
      // 2. Close DB pool
      await pool.end();
      logger.info('✅ Database pool closed.');

      // 3. Close Redis connection
      await redis.quit();
      logger.info('✅ Redis connection closed.');

      process.exit(0);
    } catch (err) {
      logger.error('❌ Error during cleanup:', { error: err.message });
      process.exit(1);
    }
  });

  // Force close after 30s (as requested)
  setTimeout(() => {
    logger.error('💥 Forceful shutdown after 30s timeout');
    process.exit(1);
  }, 30000);
};

process.on('SIGTERM', () => gracefulShutdown('SIGTERM'));
process.on('SIGINT', () => gracefulShutdown('SIGINT'));
