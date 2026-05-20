const pool = require('../config/db');

class TokenRepository {
  async create(userId, token, expiresAt) {
    await pool.query(
      'INSERT INTO refresh_tokens (user_id, token, expires_at) VALUES ($1, $2, $3)',
      [userId, token, expiresAt]
    );
  }

  async findByToken(token) {
    const result = await pool.query(
      'SELECT * FROM refresh_tokens WHERE token = $1 AND expires_at > NOW()',
      [token]
    );
    return result.rows[0];
  }

  async delete(token) {
    await pool.query('DELETE FROM refresh_tokens WHERE token = $1', [token]);
  }

  async deleteAllForUser(userId) {
    await pool.query('DELETE FROM refresh_tokens WHERE user_id = $1', [userId]);
  }
}

module.exports = new TokenRepository();
