/**
 * Migration: 202605180002_extend_shops_table
 * Purpose: Add owner_name, services, pincode, and city to shops table.
 */

exports.up = async (client) => {
  await client.query(`
    ALTER TABLE shops 
    ADD COLUMN IF NOT EXISTS owner_name VARCHAR(255),
    ADD COLUMN IF NOT EXISTS services TEXT,
    ADD COLUMN IF NOT EXISTS pincode VARCHAR(20),
    ADD COLUMN IF NOT EXISTS city VARCHAR(100);
  `);
};

exports.down = async (client) => {
  await client.query(`
    ALTER TABLE shops 
    DROP COLUMN IF EXISTS owner_name,
    DROP COLUMN IF EXISTS services,
    DROP COLUMN IF EXISTS pincode,
    DROP COLUMN IF EXISTS city;
  `);
};
