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
    // 1. Add app usage tracking to users
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS app_opens INTEGER DEFAULT 0;');
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS last_activity TIMESTAMP;');
    
    // 2. Add edit count to posts
    await pool.query('ALTER TABLE posts ADD COLUMN IF NOT EXISTS edit_count INTEGER DEFAULT 0;');
    
    console.log('✅ Analytics columns added');
    await pool.end();
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  }
}

migrate();
