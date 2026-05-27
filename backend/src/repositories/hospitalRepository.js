const pool = require('../config/db');

class HospitalRepository {
  async create(data) {
    const { name, location, contactNumber, service } = data;
    const result = await pool.query(
      `INSERT INTO hospitals (name, location, contact_number, service) 
       VALUES ($1, $2, $3, $4) RETURNING *`,
      [name, location, contactNumber, service]
    );
    return result.rows[0];
  }

  async findActive() {
    const result = await pool.query(
      `SELECT * FROM hospitals WHERE status = 'active' ORDER BY created_at DESC`
    );
    return result.rows;
  }

  async delete(id) {
    const result = await pool.query(
      `UPDATE hospitals SET status = 'deleted', updated_at = NOW() WHERE id = $1 RETURNING *`,
      [id]
    );
    return result.rows[0];
  }

  async findById(id) {
    const result = await pool.query(`SELECT * FROM hospitals WHERE id = $1`, [id]);
    return result.rows[0];
  }

  async getUserCoins(userId) {
    const result = await pool.query(`SELECT coins FROM users WHERE id = $1`, [userId]);
    return result.rows[0]?.coins || 0;
  }

  async redeemCoins(userId, hospitalId) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Deduct 50 coins
      const updateResult = await client.query(
        `UPDATE users SET coins = coins - 50 WHERE id = $1 RETURNING coins`,
        [userId]
      );
      const newCoins = updateResult.rows[0].coins;

      // 2. Insert coin redemptions record
      const redemptionResult = await client.query(
        `INSERT INTO coin_redemptions (user_id, hospital_id, coins_redeemed) 
         VALUES ($1, $2, 50) RETURNING *`,
        [userId, hospitalId]
      );
      const redemption = redemptionResult.rows[0];

      await client.query('COMMIT');
      return { newCoins, redemption };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async getRedemptions() {
    const result = await pool.query(`
      SELECT cr.id, cr.coins_redeemed, cr.created_at, 
             u.full_name as user_name, u.mobile as user_mobile,
             h.name as hospital_name, h.location as hospital_location
      FROM coin_redemptions cr
      JOIN users u ON cr.user_id = u.id
      JOIN hospitals h ON cr.hospital_id = h.id
      ORDER BY cr.created_at DESC
    `);
    return result.rows;
  }

  async getHistoryByUserId(userId) {
    const result = await pool.query(
      `
      SELECT cr.id, cr.coins_redeemed, cr.created_at,
             h.name as hospital_name, h.location as hospital_location, h.contact_number as hospital_contact
      FROM coin_redemptions cr
      JOIN hospitals h ON cr.hospital_id = h.id
      WHERE cr.user_id = $1
      ORDER BY cr.created_at DESC
    `,
      [userId]
    );
    return result.rows;
  }
}

module.exports = new HospitalRepository();
