/**
 * Migration: 202605120002_add_details_to_tasks
 * Purpose: Ensure user_crop_tasks also stores the organic/chemical details.
 */

exports.up = async (client) => {
  await client.query(`
    ALTER TABLE user_crop_tasks 
    ADD COLUMN IF NOT EXISTS organic_details TEXT,
    ADD COLUMN IF NOT EXISTS chemical_details TEXT;
  `);
};

exports.down = async (client) => {
  await client.query(`ALTER TABLE user_crop_tasks DROP COLUMN IF EXISTS organic_details, DROP COLUMN IF EXISTS chemical_details`);
};
