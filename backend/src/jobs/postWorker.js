const { Worker } = require('bullmq');
const { connection } = require('../config/redis');
const logger = require('../utils/logger');

/**
 * Worker to process jobs from the 'post-tasks' queue.
 */
const postWorker = new Worker(
  'post-tasks',
  async (job) => {
    logger.info(`Processing job ${job.id} of type ${job.name}...`);

    switch (job.name) {
      case 'process-images':
        // Simulating image optimization/resizing
        await new Promise((resolve) => setTimeout(resolve, 2000));
        logger.info(`Images processed for post ${job.data.postId}`);
        break;

      case 'send-notifications':
        // Simulating sending push notifications to nearby farmers
        await new Promise((resolve) => setTimeout(resolve, 1500));
        logger.info(`Notifications sent for post ${job.data.postId}`);
        break;

      case 'log-audit':
        // Simulating complex audit logging
        logger.info(`Audit logged for action ${job.data.action}`);
        break;

      default:
        logger.warn(`Unknown job type: ${job.name}`);
    }
  },
  { connection }
);

const pool = require('../config/db');

postWorker.on('completed', (job) => {
  logger.info(`Job ${job.id} has completed!`);
});

postWorker.on('failed', async (job, err) => {
  logger.error(`Job ${job.id} failed with error: ${err.message}`);
  
  // Dead Letter Queue: Log to database for admin review
  try {
    await pool.query(
      'INSERT INTO activity_logs (user_id, action_type, resource_type, resource_id, details) VALUES ($1, $2, $3, $4, $5)',
      [job.data.userId || 0, 'JOB_FAILED', 'job', job.id, JSON.stringify({
        name: job.name,
        data: job.data,
        error: err.message,
        attempts: job.attemptsMade,
        failedAt: new Date().toISOString()
      })]
    );
  } catch (dbErr) {
    logger.error('Failed to log failed job to database', dbErr);
  }
});

module.exports = postWorker;
