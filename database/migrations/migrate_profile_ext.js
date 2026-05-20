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
    // 1. Add pincode column
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS pincode VARCHAR(10);');
    
    // 2. Add profile_photo_url column
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS profile_photo_url VARCHAR(500);');
    
    console.log('✅ Pincode and Profile Photo columns added');
    await pool.end();
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  }
}

migrate();
