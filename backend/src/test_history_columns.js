const pool = require('c:\\Users\\sai\\Desktop\\royal_shetkari_app\\backend\\src\\config\\db');

async function test() {
  try {
    const res = await pool.query(`
      SELECT column_name, data_type 
      FROM information_schema.columns 
      WHERE table_name = 'deleted_posts_history'
    `);
    console.log("deleted_posts_history Columns:");
    console.table(res.rows);
  } catch (err) {
    console.error("DB Column Check Error:", err);
  } finally {
    pool.end();
  }
}

test();
