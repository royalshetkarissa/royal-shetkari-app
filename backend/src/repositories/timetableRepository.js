const pool = require('../config/db');

class TimetableRepository {
  async getAllCrops() {
    const result = await pool.queryWithRetry(`SELECT * FROM crops ORDER BY name ASC`);
    return result.rows;
  }

  async getCropTemplates(cropId) {
    const result = await pool.queryWithRetry(
      `SELECT * FROM crop_templates WHERE crop_id = $1 ORDER BY day_offset ASC`,
      [cropId]
    );
    return result.rows;
  }

  async createUserCropJourney(userId, cropId, plantingDate) {
    const result = await pool.queryWithRetry(
      `INSERT INTO user_crop_journeys (user_id, crop_id, planting_date) VALUES ($1, $2, $3) RETURNING *`,
      [userId, cropId, plantingDate]
    );
    return result.rows[0];
  }

  async createUserCropTasks(tasks) {
    // Bulk insert tasks
    for (const task of tasks) {
      await pool.queryWithRetry(
        `INSERT INTO user_crop_tasks (user_crop_id, template_id, task_name, task_marathi, due_date, organic_details, chemical_details, rationale_english, rationale_marathi, nutrient_content) 
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10) ON CONFLICT DO NOTHING`,
        [
          task.userCropId,
          task.templateId,
          task.taskName,
          task.taskMarathi,
          task.dueDate,
          task.organicDetails,
          task.chemicalDetails,
          task.rationaleEnglish,
          task.rationaleMarathi,
          task.nutrientContent,
        ]
      );
    }
  }

  async getUserCropJourneys(userId) {
    const result = await pool.queryWithRetry(
      `SELECT ucj.*, c.name as crop_name, c.marathi_name as crop_marathi, c.icon_name, 
              c.harvest_days_min, c.harvest_days_max
       FROM user_crop_journeys ucj
       JOIN crops c ON ucj.crop_id = c.id
       WHERE ucj.user_id = $1 AND ucj.status = 'active'
       ORDER BY ucj.created_at DESC`,
      [userId]
    );
    return result.rows;
  }

  async getTasksForJourney(userCropId) {
    const result = await pool.queryWithRetry(
      `SELECT * FROM user_crop_tasks WHERE user_crop_id = $1 ORDER BY due_date ASC`,
      [userCropId]
    );
    return result.rows;
  }

  async updateTaskCompletion(taskId, userId) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Mark task as completed if not already
      const taskResult = await client.query(
        `UPDATE user_crop_tasks 
         SET is_completed = TRUE, completed_at = NOW(), coin_awarded = TRUE 
         WHERE id = $1 AND is_completed = FALSE 
         RETURNING *`,
        [taskId]
      );

      if (taskResult.rows.length === 0) {
        await client.query('ROLLBACK');
        return null; // Already completed or not found
      }

      // 2. Award coin to user
      await client.query(`UPDATE users SET coins = coins + 1 WHERE id = $1`, [userId]);

      await client.query('COMMIT');
      return taskResult.rows[0];
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async deleteJourney(userId, journeyId) {
    await pool.queryWithRetry(
      `UPDATE user_crop_journeys SET status = 'deleted' WHERE id = $1 AND user_id = $2`,
      [journeyId, userId]
    );
  }
}

module.exports = new TimetableRepository();
