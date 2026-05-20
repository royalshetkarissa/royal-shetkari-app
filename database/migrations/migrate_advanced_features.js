const pool = require('../../backend/src/config/db');

async function migrate() {
  try {
    await pool.query(`
      -- Alter Users Table for Location
      ALTER TABLE users ADD COLUMN IF NOT EXISTS latitude NUMERIC;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS longitude NUMERIC;
      ALTER TABLE users ADD COLUMN IF NOT EXISTS current_location VARCHAR(255);

      -- Alter Posts Table for Animals and Metrics
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS latitude NUMERIC;
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS longitude NUMERIC;
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS animal_type VARCHAR(50);
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS lactation VARCHAR(50);
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS milk_per_day NUMERIC;
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS wp_clicks INTEGER DEFAULT 0;
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS call_clicks INTEGER DEFAULT 0;

      -- Crop Disease History Table
      CREATE TABLE IF NOT EXISTS crop_disease_history (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        image_url TEXT,
        disease_name VARCHAR(150),
        chemical_solution TEXT,
        organic_solution TEXT,
        is_deleted_by_user BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      -- Shops Table
      CREATE TABLE IF NOT EXISTS shops (
        id SERIAL PRIMARY KEY,
        name VARCHAR(150),
        location_name VARCHAR(150),
        latitude NUMERIC,
        longitude NUMERIC,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      -- Shop Products Table
      CREATE TABLE IF NOT EXISTS shop_products (
        id SERIAL PRIMARY KEY,
        shop_id INTEGER REFERENCES shops(id) ON DELETE CASCADE,
        name VARCHAR(150),
        image_url TEXT,
        price NUMERIC,
        is_organic BOOLEAN DEFAULT FALSE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      -- Crop Time Tables (Global Templates)
      CREATE TABLE IF NOT EXISTS crop_time_tables (
        id SERIAL PRIMARY KEY,
        crop_name VARCHAR(100),
        schedule JSONB,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );

      -- User Crop Schedules (Active timetables for a user)
      CREATE TABLE IF NOT EXISTS user_crop_schedules (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
        crop_time_table_id INTEGER REFERENCES crop_time_tables(id) ON DELETE CASCADE,
        planting_date DATE,
        is_active BOOLEAN DEFAULT TRUE,
        created_at TIMESTAMPTZ DEFAULT NOW()
      );
    `);
    console.log('✅ Advanced Features migration successful');
  } catch (err) {
    console.error('❌ Advanced Features migration failed:', err.message);
  } finally {
    await pool.end();
  }
}

migrate();
