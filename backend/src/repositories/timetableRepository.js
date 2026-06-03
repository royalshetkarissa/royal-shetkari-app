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

      // 1. Fetch task and check if it exists and who it belongs to
      const taskCheck = await client.query(
        `SELECT uct.*, ucj.user_id 
         FROM user_crop_tasks uct
         JOIN user_crop_journeys ucj ON uct.user_crop_id = ucj.id
         WHERE uct.id = $1`,
        [taskId]
      );

      if (taskCheck.rows.length === 0) {
        await client.query('ROLLBACK');
        return { success: false, error: 'TASK_NOT_FOUND' };
      }

      const task = taskCheck.rows[0];

      if (task.user_id !== parseInt(userId)) {
        await client.query('ROLLBACK');
        return { success: false, error: 'NOT_OWNER' };
      }

      if (task.is_completed) {
        await client.query('ROLLBACK');
        return { success: false, error: 'ALREADY_COMPLETED' };
      }

      // 2. Mark task as completed
      const taskResult = await client.query(
        `UPDATE user_crop_tasks 
         SET is_completed = TRUE, completed_at = NOW(), coin_awarded = TRUE 
         WHERE id = $1 
         RETURNING *`,
        [taskId]
      );

      // 3. Award coin to user
      await client.query(`UPDATE users SET coins = COALESCE(coins, 0) + 1 WHERE id = $1`, [userId]);

      await client.query('COMMIT');
      return { success: true, task: taskResult.rows[0] };
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

  async getDailyTasks(userId) {
    const result = await pool.queryWithRetry(
      `SELECT 
        uct.id,
        uct.task_name,
        uct.task_marathi,
        uct.organic_details,
        uct.due_date,
        ucj.planting_date,
        c.name as crop_name,
        c.marathi_name as crop_marathi
       FROM user_crop_tasks uct
       JOIN user_crop_journeys ucj ON uct.user_crop_id = ucj.id
       JOIN crops c ON ucj.crop_id = c.id
       WHERE ucj.user_id = $1 
         AND ucj.status = 'active'
         AND uct.due_date = CURRENT_DATE
         AND uct.is_completed = FALSE
       ORDER BY c.name ASC, uct.id ASC`,
      [userId]
    );
    return result.rows;
  }

  async getCropDiseases(cropId) {
    const result = await pool.queryWithRetry(
      `SELECT * FROM crop_diseases WHERE crop_id = $1 ORDER BY id ASC`,
      [cropId]
    );
    return result.rows;
  }
}

module.exports = new TimetableRepository();
