const pool = require('../config/db');

exports.up = async () => {
  await pool.query('ALTER TABLE otps ADD COLUMN IF NOT EXISTS attempts INTEGER DEFAULT 0');
};

exports.down = async () => {
  await pool.query('ALTER TABLE otps DROP COLUMN IF EXISTS attempts');
};
