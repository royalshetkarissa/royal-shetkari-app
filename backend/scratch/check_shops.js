const pool = require('../src/config/db');

async function run() {
  try {
    const res = await pool.query('SELECT id, name, profile_photo, images FROM shops');
    console.log('SHOPS IN DB:');
    console.log(JSON.stringify(res.rows, null, 2));
    process.exit(0);
  } catch (err) {
    console.error(err);
    process.exit(1);
  }
}

run();
