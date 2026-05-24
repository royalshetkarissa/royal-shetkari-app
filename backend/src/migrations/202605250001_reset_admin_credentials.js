/**
 * Migration: 202605250001_reset_admin_credentials
 * Purpose: Update password and grant admin permissions for user 8605889356 on the live database.
 */
const bcrypt = require('bcrypt');

exports.up = async (client) => {
  const mobile = '8605889356';
  const plainPassword = 'admin@123';
  const hashedPassword = await bcrypt.hash(plainPassword, 10);

  // Check if user exists
  const checkUser = await client.query('SELECT id FROM users WHERE mobile = $1', [mobile]);
  if (checkUser.rows.length === 0) {
    // Insert if user not found
    await client.query(
      `INSERT INTO users (full_name, mobile, password, village, state, pincode, is_admin, role) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      ['Admin User', mobile, hashedPassword, 'Admin Village', 'Maharashtra', '411001', true, 'admin']
    );
  } else {
    // Update password and admin flags if user found
    await client.query(
      `UPDATE users SET password = $1, is_admin = $2, role = $3 WHERE mobile = $4`,
      [hashedPassword, true, 'admin', mobile]
    );
  }
};

exports.down = async (client) => {
  // No rollback operation needed for safety of admin user status
};
