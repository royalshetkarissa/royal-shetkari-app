const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  password: 'postgres',
  host: 'localhost',
  port: 5432,
  database: 'royal_shetkari_db',
});

async function migrate() {
  try {
    await pool.query('ALTER TABLE posts ADD COLUMN IF NOT EXISTS old_price DECIMAL(10,2);');
    console.log('✅ Successfully added old_price column');
    await pool.end();
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  }
}

migrate();
