const pool = require('../config/db');
const bcrypt = require('bcrypt');

class UserRepository {
  async findByMobile(mobile) {
    const result = await pool.query('SELECT * FROM users WHERE mobile = $1', [mobile]);
    return result.rows[0];
  }

  async findById(id) {
    const result = await pool.query(
      'SELECT id, full_name, mobile, email, village, state, pincode, latitude, longitude, current_location, profile_photo_url, is_admin, role, permissions, coins FROM users WHERE id = $1',
      [id]
    );
    return result.rows[0];
  }

  async create(data) {
    const { fullName, mobile, email, password, village, state, pincode, latitude, longitude, currentLocation } = data;
    const hashedPassword = await bcrypt.hash(password, 10);
    const result = await pool.query(
      'INSERT INTO users (full_name, mobile, email, password, village, state, pincode, latitude, longitude, current_location) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) RETURNING id, full_name, mobile',
      [fullName, mobile, email || null, hashedPassword, village, state || null, pincode || null, latitude || null, longitude || null, currentLocation || null]
    );
    return result.rows[0];
  }

  async updateProfile(userId, data) {
    const { fullName, email, village, state, pincode, latitude, longitude, currentLocation } = data;
    const result = await pool.query(
      `UPDATE users SET full_name = $1, email = $2, village = $3, state = $4, pincode = $5, latitude = $6, longitude = $7, current_location = $8 WHERE id = $9 
       RETURNING id, full_name, mobile, email, village, state, pincode, latitude, longitude, current_location, profile_photo_url, is_admin, coins`,
      [fullName, email, village, state, pincode, latitude || null, longitude || null, currentLocation || null, userId]
    );
    return result.rows[0];
  }

  async updateProfilePhoto(userId, photoUrl) {
    await pool.query('UPDATE users SET profile_photo_url = $1 WHERE id = $2', [photoUrl, userId]);
  }

  async createOTP(mobile, otp, expiry) {
    await pool.query('INSERT INTO otps (mobile, otp, expires_at) VALUES ($1, $2, $3)', [mobile, otp, expiry]);
  }

  async findValidOTP(mobile, otp) {
    const result = await pool.query(
      'SELECT * FROM otps WHERE mobile = $1 AND otp = $2 AND expires_at > NOW() AND is_used = false',
      [mobile, otp]
    );
    return result.rows[0];
  }

  async useOTP(otpId) {
    await pool.query('UPDATE otps SET is_used = true WHERE id = $1', [otpId]);
  }

  async verifyUser(mobile) {
    await pool.query('UPDATE users SET is_verified = true, app_opens = app_opens + 1, last_activity = NOW() WHERE mobile = $1', [mobile]);
  }

  async updatePasswordByMobile(mobile, newPassword) {
    const hashedPassword = await bcrypt.hash(newPassword, 10);
    const result = await pool.query(
      'UPDATE users SET password = $1 WHERE mobile = $2 RETURNING id, full_name, mobile',
      [hashedPassword, mobile]
    );
    return result.rows[0];
  }
}

module.exports = new UserRepository();
