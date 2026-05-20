/**
 * Migration: 202605120008_fertilizer_shop_module
 * Purpose: Full production schema for Fertilizer Shops.
 */

exports.up = async (client) => {
  // 1. Drop existing placeholder shops table if it exists
  await client.query(`DROP TABLE IF EXISTS shops CASCADE;`);

  // 2. Create production Shops Table
  await client.query(`
    CREATE TABLE shops (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      profile_photo TEXT,
      address TEXT NOT NULL,
      contact_mobile VARCHAR(20) NOT NULL,
      whatsapp_number VARCHAR(20),
      categories JSONB DEFAULT '[]'::jsonb, -- ['seeds', 'organic', 'insecticides', etc.]
      images JSONB DEFAULT '[]'::jsonb, -- Max 10 images
      latitude NUMERIC(10, 8),
      longitude NUMERIC(11, 8),
      status VARCHAR(20) DEFAULT 'inactive', -- active, inactive, deleted
      owner_id INTEGER REFERENCES users(id), -- Admin who added it
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX idx_shops_location ON shops(latitude, longitude);
    CREATE INDEX idx_shops_status ON shops(status);
  `);

  // 3. Create Shop Clicks Table
  await client.query(`
    CREATE TABLE IF NOT EXISTS shop_clicks (
      id SERIAL PRIMARY KEY,
      shop_id INTEGER REFERENCES shops(id) ON DELETE CASCADE,
      user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      click_type VARCHAR(20) NOT NULL, -- 'call', 'whatsapp', 'view'
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX idx_shop_clicks_shop ON shop_clicks(shop_id);
  `);
};

exports.down = async (client) => {
  await client.query(`DROP TABLE IF EXISTS shop_clicks;`);
  await client.query(`DROP TABLE IF EXISTS shops;`);
};
