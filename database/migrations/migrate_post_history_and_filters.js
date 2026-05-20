const pool = require('../../backend/src/config/db');

async function migrate() {
  try {
    console.log('🔄 Running post history and deleted posts logging migration...');
    
    await pool.query(`
      -- 1. Add deleted_at column to posts if not exists
      ALTER TABLE posts ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

      -- 2. Create deleted_posts_history table
      CREATE TABLE IF NOT EXISTS deleted_posts_history (
        id SERIAL PRIMARY KEY,
        post_id INTEGER NOT NULL,
        user_id INTEGER,
        category VARCHAR(50),
        title VARCHAR(150),
        description TEXT,
        price NUMERIC,
        old_price NUMERIC,
        location VARCHAR(150),
        latitude NUMERIC,
        longitude NUMERIC,
        animal_type VARCHAR(50),
        lactation VARCHAR(50),
        milk_per_day NUMERIC,
        wp_clicks INTEGER DEFAULT 0,
        call_clicks INTEGER DEFAULT 0,
        contact_mobile VARCHAR(15),
        images JSONB DEFAULT '[]',
        image_url TEXT,
        likes_count INTEGER DEFAULT 0,
        views_count INTEGER DEFAULT 0,
        status VARCHAR(20),
        post_created_at TIMESTAMPTZ,
        deleted_at TIMESTAMPTZ DEFAULT NOW(),
        comments JSONB DEFAULT '[]',
        likes JSONB DEFAULT '[]',
        saves JSONB DEFAULT '[]'
      );
    `);
    
    console.log('✅ Post history and deleted posts logging migration successful!');
  } catch (err) {
    console.error('❌ Post history migration failed:', err.message);
    process.exit(1);
  } finally {
    await pool.end();
  }
}

migrate();
