/**
 * Migration: 202605180001_hospital_coins_module
 * Purpose: Full production schema for Hospitals and Coin Redemptions.
 */

exports.up = async (client) => {
  // 1. Create hospitals table
  await client.query(`
    CREATE TABLE IF NOT EXISTS hospitals (
      id SERIAL PRIMARY KEY,
      name VARCHAR(255) NOT NULL,
      location VARCHAR(255) NOT NULL,
      contact_number VARCHAR(20) NOT NULL,
      service TEXT NOT NULL,
      status VARCHAR(20) DEFAULT 'active', -- active, deleted
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
      updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX IF NOT EXISTS idx_hospitals_status ON hospitals(status);
  `);

  // 2. Create coin_redemptions table
  await client.query(`
    CREATE TABLE IF NOT EXISTS coin_redemptions (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      hospital_id INTEGER REFERENCES hospitals(id) ON DELETE CASCADE,
      coins_redeemed INTEGER DEFAULT 50,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX IF NOT EXISTS idx_redemptions_user ON coin_redemptions(user_id);
    CREATE INDEX IF NOT EXISTS idx_redemptions_hospital ON coin_redemptions(hospital_id);
  `);
};

exports.down = async (client) => {
  await client.query(`DROP TABLE IF EXISTS coin_redemptions CASCADE;`);
  await client.query(`DROP TABLE IF EXISTS hospitals CASCADE;`);
};
