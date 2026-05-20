const fs = require('fs');
const path = require('path');
const pool = require('../backend/src/config/db');

/**
 * Migration Runner
 */
const migrate = async (direction = 'up') => {
  const sqlFile = direction === 'up' ? 'schema.sql' : 'rollback.sql';
  const filePath = path.join(__dirname, sqlFile);

  if (!fs.existsSync(filePath)) {
    console.error(`❌ ${sqlFile} not found!`);
    process.exit(1);
  }

  const sql = fs.readFileSync(filePath, 'utf8');

  try {
    console.log(`🚀 Running database ${direction} (${sqlFile})...`);
    await pool.query(sql);
    console.log(`✅ Database ${direction} successful.`);
    process.exit(0);
  } catch (err) {
    console.error(`❌ Database ${direction} failed:`, err.message);
    process.exit(1);
  }
};

const action = process.argv[2] || 'up';
migrate(action);
