const bootstrapAdmin = require('../src/utils/bootstrapAdmin');
const pool = require('../src/config/db');

async function run() {
  try {
    await bootstrapAdmin();
  } finally {
    await pool.end();
  }
}

run();
