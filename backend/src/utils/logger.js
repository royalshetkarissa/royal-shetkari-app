const winston = require('winston');
require('winston-daily-rotate-file');
const path = require('path');

const logFormat = winston.format.combine(
  winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
  winston.format.errors({ stack: true }),
  winston.format.json()
);

const logger = winston.createLogger({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  format: logFormat,
  defaultMeta: { service: 'royal-shetkari-backend' },
  transports: [
    new winston.transports.DailyRotateFile({
      filename: path.join(__dirname, '../../logs/error-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      level: 'error',
      maxFiles: '30d',
    }),
    new winston.transports.DailyRotateFile({
      filename: path.join(__dirname, '../../logs/combined-%DATE%.log'),
      datePattern: 'YYYY-MM-DD',
      maxFiles: '14d',
    }),
  ],
});

logger.add(
  new winston.transports.Console({
    format: process.env.NODE_ENV === 'production'
      ? winston.format.combine(
          winston.format.timestamp({ format: 'YYYY-MM-DD HH:mm:ss' }),
          winston.format.errors({ stack: true }),
          winston.format.json()
        )
      : winston.format.combine(winston.format.colorize(), winston.format.simple()),
  })
);

/**
 * Helper to log structured activity to BOTH File and Database.
 */
logger.logActivity = async (
  userId,
  action,
  resourceType,
  resourceId,
  details = {},
  requestId = null
) => {
  logger.info({
    requestId,
    userId,
    action,
    resourceType,
    resourceId,
    details,
    message: `Activity: ${action} on ${resourceType} (${resourceId}) by User ${userId}`,
  });

  try {
    // Dynamically require to break circular dependency
    const pool = require('../config/db');
    await pool.query(
      'INSERT INTO activity_logs (user_id, action_type, resource_type, resource_id, details) VALUES ($1, $2, $3, $4, $5)',
      [userId, action, resourceType, resourceId, JSON.stringify({ ...details, requestId })]
    );
  } catch (err) {
    console.error('❌ Failed to save activity log to database:', err.message);
  }
};

module.exports = logger;
