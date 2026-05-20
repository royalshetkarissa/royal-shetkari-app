const pool = require('../config/db');

class AnalyticsRepository {
  async saveImpression({ userId, activeType, activeId, startTime, endTime, durationSeconds }) {
    const activeDate = new Date(startTime).toISOString().split('T')[0];

    // Check if there is an impression within the same day for this specific active item
    const existing = await pool.queryWithRetry(
      `SELECT id, seen_count, duration_seconds FROM dashboard_impressions 
       WHERE user_id = $1 AND active_type = $2 AND active_id = $3 AND active_date = $4 
       ORDER BY created_at DESC LIMIT 1`,
      [userId, activeType, activeId, activeDate]
    );

    if (existing.rows.length > 0) {
      // If matches the exact day, increment seen_count, update end_time, and add duration
      const id = existing.rows[0].id;
      const newSeenCount = existing.rows[0].seen_count + 1;
      const newDuration = existing.rows[0].duration_seconds + durationSeconds;

      const result = await pool.queryWithRetry(
        `UPDATE dashboard_impressions 
         SET seen_count = $1, end_time = $2, duration_seconds = $3
         WHERE id = $4 RETURNING *`,
        [newSeenCount, endTime, newDuration, id]
      );
      return result.rows[0];
    } else {
      // Otherwise, insert new impression row
      const result = await pool.queryWithRetry(
        `INSERT INTO dashboard_impressions 
         (user_id, active_type, active_id, active_date, seen_count, start_time, end_time, duration_seconds) 
         VALUES ($1, $2, $3, $4, 1, $5, $6, $7) RETURNING *`,
        [userId, activeType, activeId, activeDate, startTime, endTime, durationSeconds]
      );
      return result.rows[0];
    }
  }
}

module.exports = new AnalyticsRepository();
