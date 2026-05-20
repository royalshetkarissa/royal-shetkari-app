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
    // 1. Create activity_logs table for advanced auditing
    await pool.query(`
      CREATE TABLE IF NOT EXISTS activity_logs (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
        action_type VARCHAR(50) NOT NULL, -- LOGIN, CREATE_POST, EDIT_POST, DELETE_POST, BOOK_CALL
        resource_type VARCHAR(50),      -- post, booking, user
        resource_id INTEGER,
        details JSONB,                   -- Advanced JSON storage for old/new values
        ip_address VARCHAR(45),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      );
    `);
    
    console.log('✅ Advanced Activity Log table created');
    await pool.end();
  } catch (err) {
    console.error('❌ Migration failed:', err.message);
    process.exit(1);
  }
}

migrate();
