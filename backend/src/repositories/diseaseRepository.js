const pool = require('../config/db');

class DiseaseRepository {
  async saveHistory(data) {
    const { userId, imageUrl, diseaseName, chemicalSolution, organicSolution } = data;
    const result = await pool.queryWithRetry(
      `INSERT INTO crop_disease_history (user_id, image_url, disease_name, chemical_solution, organic_solution) 
       VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [userId, imageUrl, diseaseName, chemicalSolution, organicSolution]
    );
    return result.rows[0];
  }

  async getHistoryByUserId(userId) {
    const result = await pool.queryWithRetry(
      `SELECT * FROM crop_disease_history WHERE user_id = $1 AND is_deleted_by_user = FALSE ORDER BY created_at DESC`,
      [userId]
    );
    return result.rows;
  }

  async softDeleteHistory(id, userId) {
    const result = await pool.queryWithRetry(
      `UPDATE crop_disease_history SET is_deleted_by_user = TRUE WHERE id = $1 AND user_id = $2 RETURNING *`,
      [id, userId]
    );
    return result.rows[0];
  }
}

module.exports = new DiseaseRepository();
