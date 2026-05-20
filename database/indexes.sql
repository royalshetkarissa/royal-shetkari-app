-- Performance Indexes for Royal Shetkari DB

-- User lookups
CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile);
CREATE INDEX IF NOT EXISTS idx_users_email ON users(email);

-- Post filtering and sorting
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_category ON posts(category);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_status ON posts(status);

-- Social interactions
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON post_comments(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_saved_post_id ON saved_posts(post_id);

-- Logging
CREATE INDEX IF NOT EXISTS idx_logs_created_at ON activity_logs(created_at DESC);
