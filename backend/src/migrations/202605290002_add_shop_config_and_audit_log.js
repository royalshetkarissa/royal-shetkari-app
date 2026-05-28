/**
 * Migration: 202605290002_add_shop_config_and_audit_log
 * Purpose: Add coin configuration fields to shops and create a table for tracking modifications.
 */

exports.up = async (client) => {
  // 1. Add config columns to shops
  await client.query(`
    ALTER TABLE shops 
    ADD COLUMN IF NOT EXISTS redeem_coin_cost INTEGER DEFAULT 50,
    ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC(5, 2) DEFAULT 5.0;
  `);

  // 2. Create shop audit logs table
  await client.query(`
    CREATE TABLE IF NOT EXISTS shop_audit_logs (
      id SERIAL PRIMARY KEY,
      shop_id INTEGER REFERENCES shops(id) ON DELETE CASCADE,
      changed_by_user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
      field_name VARCHAR(100) NOT NULL,
      old_value TEXT,
      new_value TEXT,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX IF NOT EXISTS idx_shop_audit_logs_shop ON shop_audit_logs(shop_id);
    CREATE INDEX IF NOT EXISTS idx_shop_audit_logs_time ON shop_audit_logs(created_at);
  `);
};

exports.down = async (client) => {
  await client.query(`DROP TABLE IF EXISTS shop_audit_logs CASCADE;`);
  await client.query(`
    ALTER TABLE shops 
    DROP COLUMN IF EXISTS redeem_coin_cost,
    DROP COLUMN IF EXISTS discount_percentage;
  `);
};
