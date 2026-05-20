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
    // 1. Add is_admin column
    await pool.query('ALTER TABLE users ADD COLUMN IF NOT EXISTS is_admin BOOLEAN DEFAULT FALSE;');
    console.log('✅ Successfully added is_admin column');
    
    // 2. Set shivdeep (8605889356) as admin
    await pool.query("UPDATE users SET is_admin = TRUE WHERE mobile = '8605889356';");
    console.log('👑 Set 8605889356 as ADMIN');
    
    await pool.end();
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  }
}

migrate();
