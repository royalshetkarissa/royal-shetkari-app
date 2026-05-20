const { Pool } = require('pg');

const pool = new Pool({
  user: 'postgres',
  host: 'localhost',
  database: 'royal_shetkari_db',
  password: 'postgres',
  port: 5432,
});

async function checkPosts() {
  try {
    const res = await pool.query('SELECT * FROM posts');
    console.log('--- ALL POSTS ---');
    console.log(res.rows);
    
    const users = await pool.query('SELECT id, full_name, mobile FROM users');
    console.log('--- ALL USERS ---');
    console.log(users.rows);
    
    await pool.end();
  } catch (err) {
    console.error(err);
  }
}

checkPosts();
