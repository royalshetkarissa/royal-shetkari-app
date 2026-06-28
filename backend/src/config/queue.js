const { Queue } = require('bullmq');
const { connection } = require('./redis');

// Centralize queue definitions
const queues = {
  diseaseScanQueue: new Queue('disease-scan', { connection }),
};

module.exports = queues;
