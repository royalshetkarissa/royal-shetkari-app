require('dotenv').config();
const migrationRunner = require('./src/utils/migrationRunner');
const logger = require('./src/utils/logger');

async function run() {
  try {
    logger.info('Starting manual migration run...');
    await migrationRunner.up();
    logger.info('Migration run completed.');
    process.exit(0);
  } catch (err) {
    logger.error('Migration run failed:', err);
    process.exit(1);
  }
}

run();
