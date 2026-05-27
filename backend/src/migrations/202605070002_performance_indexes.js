/**
 * Performance Optimization: B-tree and GIN Indexes.
 * Converts O(n) table scans to O(log n) lookups.
 */
exports.up = async (client) => {
  // Users: O(1) mobile lookup
  await client.query('CREATE INDEX IF NOT EXISTS idx_users_mobile ON users(mobile)');

  // Posts: Multi-column index for common filtering (O(log n))
  await client.query(
    'CREATE INDEX IF NOT EXISTS idx_posts_cat_status_date ON posts(category, status, created_at DESC)'
  );
  await client.query('CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id)');

  // Interactions: Speed up joins and counts
  await client.query('CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id)');
  await client.query(
    'CREATE INDEX IF NOT EXISTS idx_post_comments_post_id ON post_comments(post_id)'
  );
  await client.query('CREATE INDEX IF NOT EXISTS idx_saved_posts_user_id ON saved_posts(user_id)');

  // OTPs: Speed up verification
  await client.query(
    'CREATE INDEX IF NOT EXISTS idx_otps_mobile_expiry ON otps(mobile, expires_at)'
  );

  // Activity Logs: GIN index for fast JSONB search
  await client.query(
    'CREATE INDEX IF NOT EXISTS idx_activity_logs_details ON activity_logs USING GIN (details)'
  );
};

exports.down = async (client) => {
  await client.query('DROP INDEX IF EXISTS idx_users_mobile');
  await client.query('DROP INDEX IF EXISTS idx_posts_cat_status_date');
  await client.query('DROP INDEX IF EXISTS idx_posts_user_id');
  await client.query('DROP INDEX IF EXISTS idx_post_likes_post_id');
  await client.query('DROP INDEX IF EXISTS idx_post_likes_user_id');
  await client.query('DROP INDEX IF EXISTS idx_post_comments_post_id');
  await client.query('DROP INDEX IF EXISTS idx_saved_posts_user_id');
  await client.query('DROP INDEX IF EXISTS idx_otps_mobile_expiry');
  await client.query('DROP INDEX IF EXISTS idx_activity_logs_details');
};
