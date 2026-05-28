/**
 * Migration: 202605290003_create_featured_shop_schedules
 * Purpose: Track which shop is featured on the home screen for which date.
 */

exports.up = async (client) => {
  await client.query(`
    CREATE TABLE IF NOT EXISTS featured_shop_schedules (
      id SERIAL PRIMARY KEY,
      shop_id INTEGER NOT NULL REFERENCES shops(id) ON DELETE CASCADE,
      featured_date DATE NOT NULL UNIQUE,
      is_new_arrival BOOLEAN NOT NULL DEFAULT FALSE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX IF NOT EXISTS idx_featured_shop_schedules_shop ON featured_shop_schedules(shop_id);
    CREATE INDEX IF NOT EXISTS idx_featured_shop_schedules_date ON featured_shop_schedules(featured_date);
  `);
};

exports.down = async (client) => {
  await client.query(`DROP TABLE IF EXISTS featured_shop_schedules CASCADE;`);
};
