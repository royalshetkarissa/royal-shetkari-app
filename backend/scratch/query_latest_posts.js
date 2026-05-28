const { Client } = require('pg');

const client = new Client({
  connectionString: 'postgresql://postgres:oXKvtMVSifRhvjtOvRFmiSXlltUfgjSu@kodama.proxy.rlwy.net:54388/railway',
  ssl: {
    rejectUnauthorized: false
  }
});

async function main() {
  await client.connect();
  console.log('Connected to Database successfully!');
  
  const res = await client.query('SELECT id, title, image_url, images, created_at FROM posts ORDER BY id DESC LIMIT 5');
  console.log('Latest 5 posts:');
  console.log(JSON.stringify(res.rows, null, 2));

  await client.end();
}

main().catch(console.error);
