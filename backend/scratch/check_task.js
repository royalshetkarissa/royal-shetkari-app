const pool = require('../src/config/db');

async function checkTask() {
  try {
    const taskRes = await pool.query('SELECT * FROM user_crop_tasks WHERE id = 153');
    console.log('--- TASK 153 DETAILS ---');
    console.log(taskRes.rows[0]);

    if (taskRes.rows.length > 0) {
      const journeyId = taskRes.rows[0].user_crop_id;
      const journeyRes = await pool.query('SELECT * FROM user_crop_journeys WHERE id = $1', [journeyId]);
      console.log('--- ASSOCIATED JOURNEY ---');
      console.log(journeyRes.rows[0]);

      if (journeyRes.rows.length > 0) {
        const userId = journeyRes.rows[0].user_id;
        const userRes = await pool.query('SELECT id, full_name, mobile, coins FROM users WHERE id = $1', [userId]);
        console.log('--- ASSOCIATED USER ---');
        console.log(userRes.rows[0]);
      }
    } else {
      console.log('Task 153 does not exist in the database.');
    }
  } catch (err) {
    console.error('Error running check script:', err);
  } finally {
    await pool.end();
  }
}

checkTask();
