const { Queue } = require('bullmq');
const { connection } = require('../config/redis');

// Create a new queue
const postQueue = new Queue('post-tasks', { connection });

/**
 * Add a job to the post queue.
 * @param {string} name - Name of the job.
 * @param {object} data - Job data.
 */
const addPostJob = async (name, data) => {
  await postQueue.add(name, data, {
    attempts: 3,
    backoff: {
      type: 'exponential',
      delay: 1000,
    },
    removeOnComplete: true,
  });
};

module.exports = {
  postQueue,
  addPostJob,
};
