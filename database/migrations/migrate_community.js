const { Pool } = require('pg');
const pool = new Pool({
  user: 'postgres',
  password: 'postgres',
  host: 'localhost',
  port: 5432,
  database: 'royal_shetkari_db',
});

async function migrate() {
  try {
    await pool.query(`
      -- Update posts table
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS images JSONB DEFAULT '[]';
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS views_count INTEGER DEFAULT 0;
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS contact_number VARCHAR(15);

      -- Likes table
      CREATE TABLE IF NOT EXISTS post_likes (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        post_id INTEGER REFERENCES posts(id),
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(user_id, post_id)
      );

      -- Saved posts table
      CREATE TABLE IF NOT EXISTS saved_posts (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        post_id INTEGER REFERENCES posts(id),
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(user_id, post_id)
      );

      -- Comments table
      CREATE TABLE IF NOT EXISTS post_comments (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        post_id INTEGER REFERENCES posts(id),
        content TEXT NOT NULL,
        likes_count INTEGER DEFAULT 0,
        created_at TIMESTAMP DEFAULT NOW()
      );

      -- Comment Likes table
      CREATE TABLE IF NOT EXISTS comment_likes (
        id SERIAL PRIMARY KEY,
        user_id INTEGER REFERENCES users(id),
        comment_id INTEGER REFERENCES post_comments(id),
        created_at TIMESTAMP DEFAULT NOW(),
        UNIQUE(user_id, comment_id)
      );
    `);
    console.log('✅ Community migration successful');
  } catch (err) {
    console.error('❌ Community migration failed:', err.message);
  } finally {
    await pool.end();
  }
}

migrate();
