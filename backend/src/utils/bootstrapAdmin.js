const bcrypt = require('bcrypt');
const pool = require('../config/db');
const logger = require('./logger');
const env = require('../config/env');

async function bootstrapAdmin() {
  const { NAME, MOBILE, EMAIL, PASSWORD } = env.SUPER_ADMIN;

  if (!PASSWORD) {
    if (env.NODE_ENV === 'production') {
      logger.error('❌ SUPER_ADMIN_PASSWORD is required in production environment.');
      process.exit(1);
    }
    logger.warn('⚠️ SUPER_ADMIN_PASSWORD is not set. Skipping admin bootstrap in non-production.');
    return;
  }

  try {
    const check = await pool.query(
      'SELECT id FROM users WHERE mobile = $1 OR (email IS NOT NULL AND email = $2)',
      [MOBILE, EMAIL || '']
    );
    if (check.rows.length > 0) {
      logger.info('Super Admin account already exists (by mobile or email). Skipping bootstrap.');
      return;
    }

    logger.info('Bootstrapping Super Admin account...');
    const hashedPassword = await bcrypt.hash(PASSWORD, 10);
    await pool.query(
      "INSERT INTO users (full_name, mobile, email, password, is_admin, role, village, state, pincode) VALUES ($1, $2, $3, $4, TRUE, 'superuser', $5, $6, $7)",
      [NAME, MOBILE, EMAIL || null, hashedPassword, 'System Village', 'Maharashtra', '411001']
    );
    logger.info('✅ Super Admin account bootstrapped successfully.');
  } catch (err) {
    logger.error('❌ Failed to bootstrap Super Admin account:', { error: err.message });
    console.error('❌ Failed to bootstrap Super Admin account details:', err);
    if (env.NODE_ENV === 'production') {
      process.exit(1);
    }
  }
}

module.exports = bootstrapAdmin;
