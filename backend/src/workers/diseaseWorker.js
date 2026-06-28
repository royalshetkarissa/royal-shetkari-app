const { Worker } = require('bullmq');
const { connection } = require('../config/redis');
const diseaseService = require('../services/diseaseService');
const logger = require('../utils/logger');

// The worker processes jobs from the 'disease-scan' queue
const diseaseWorker = new Worker(
  'disease-scan',
  async (job) => {
    logger.info(`Processing disease scan job ${job.id} for user ${job.data.userId}`);
    
    try {
      // Run the heavy/slow API call and db insertion
      const result = await diseaseService.scanDisease(job.data.userId, job.data.imageUrl);
      
      // The return value will be stored in the job's returnvalue in Redis
      return result;
    } catch (error) {
      logger.error(`Error processing disease scan job ${job.id}:`, error);
      throw error; // BullMQ will handle retries based on configuration
    }
  },
  {
    connection,
    concurrency: 5, // Process up to 5 images simultaneously
  }
);

diseaseWorker.on('completed', (job) => {
  logger.info(`Job ${job.id} has completed!`);
});

diseaseWorker.on('failed', (job, err) => {
  logger.error(`Job ${job.id} has failed with ${err.message}`);
});

module.exports = diseaseWorker;
