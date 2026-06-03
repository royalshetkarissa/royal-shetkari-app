/**
 * Migration: 202606040002_fix_user_coins_null
 * Purpose: Update any existing NULL coin values to 0 and enforce NOT NULL DEFAULT 0 constraint on users.coins.
 */

exports.up = async (client) => {
  // 1. Ensure the coins column exists (should exist from advanced_timetable migration)
  await client.query(`
    ALTER TABLE users ADD COLUMN IF NOT EXISTS coins INTEGER DEFAULT 0;
  `);

  // 2. Backfill any NULL coin values to 0
  await client.query(`
    UPDATE users SET coins = 0 WHERE coins IS NULL;
  `);

  // 3. Alter column default and add NOT NULL constraint
  await client.query(`
    ALTER TABLE users ALTER COLUMN coins SET DEFAULT 0;
    ALTER TABLE users ALTER COLUMN coins SET NOT NULL;
  `);
};

exports.down = async (client) => {
  // Remove NOT NULL constraint if rolling back
  await client.query(`
    ALTER TABLE users ALTER COLUMN coins DROP NOT NULL;
  `);
};
