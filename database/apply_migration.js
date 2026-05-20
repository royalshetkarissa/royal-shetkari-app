const fs = require('fs');
const path = require('path');
const { Pool } = require('pg');
require('dotenv').config({ path: path.join(__dirname, '../backend/.env') });

const poolConfig = process.env.DATABASE_URL ? {
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.NODE_ENV === 'production' ? { rejectUnauthorized: false } : false
} : {
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
};

const pool = new Pool(poolConfig);

async function runMigration() {
  try {
    console.log('🔄 Connecting to database...');
    const sqlPath = path.join(__dirname, 'migrate.sql');
    const sql = fs.readFileSync(sqlPath, 'utf8');

    console.log('🚀 Executing migration script...');
    await pool.query(sql);

    console.log('✅ Migration successful! Your database is now up to date.');
  } catch (error) {
    console.error('❌ Migration failed:');
    console.error(error.message);
  } finally {
    await pool.end();
  }
}

runMigration();
