/**
 * Migration: 202605290002_add_shop_discount_config
 * Purpose: Add dynamic coin and discount configuration to shops table.
 */

exports.up = async (client) => {
  await client.query(`
    ALTER TABLE shops 
    ADD COLUMN IF NOT EXISTS coins_required INTEGER DEFAULT 50,
    ADD COLUMN IF NOT EXISTS discount_percentage NUMERIC DEFAULT 5.0;
  `);
};

exports.down = async (client) => {
  await client.query(`
    ALTER TABLE shops 
    DROP COLUMN IF EXISTS coins_required,
    DROP COLUMN IF EXISTS discount_percentage;
  `);
};
