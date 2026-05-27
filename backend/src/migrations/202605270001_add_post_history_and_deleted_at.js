/**
 * Migration: 202605270001_add_post_history_and_deleted_at
 * Purpose: Add deleted_at column to posts and create deleted_posts_history table for soft deletion functionality.
 */
exports.up = async (client) => {
  await client.query(`
    -- 1. Add deleted_at column to posts if not exists
    ALTER TABLE posts ADD COLUMN IF NOT EXISTS deleted_at TIMESTAMPTZ;

    -- 2. Create deleted_posts_history table if not exists
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
};

exports.down = async (client) => {
  await client.query(`
    DROP TABLE IF EXISTS deleted_posts_history;
    ALTER TABLE posts DROP COLUMN IF EXISTS deleted_at;
  `);
};
