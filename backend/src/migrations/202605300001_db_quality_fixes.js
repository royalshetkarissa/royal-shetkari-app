/**
 * Migration: 202605300001_db_quality_fixes
 * Purpose: Prevent double-spend concurrency exploits on coins and index foreign keys.
 */

exports.up = async (client) => {
  // 1. Enforce coin balance integrity check constraint
  await client.query('ALTER TABLE users ADD CONSTRAINT check_coins_positive CHECK (coins >= 0)');

  // 2. Performance: Add indices for foreign key relationships to prevent full table scans
  await client.query('CREATE INDEX IF NOT EXISTS idx_post_comments_user_id ON post_comments(user_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_saved_posts_post_id ON saved_posts(post_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_call_bookings_user_id ON call_bookings(user_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_refresh_tokens_user_id ON refresh_tokens(user_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_activity_logs_user_id ON activity_logs(user_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_crop_disease_history_user_id ON crop_disease_history(user_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_shop_products_shop_id ON shop_products(shop_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_user_crop_schedules_user_id ON user_crop_schedules(user_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_user_crop_schedules_crop_id ON user_crop_schedules(crop_time_table_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_dashboard_impressions_user_id ON dashboard_impressions(user_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_shop_coin_claims_user_id ON shop_coin_claims(user_id)');
  await client.query('CREATE INDEX IF NOT EXISTS idx_shop_coin_claims_shop_id ON shop_coin_claims(shop_id)');
};

exports.down = async (client) => {
  // Rollbacks
  await client.query('ALTER TABLE users DROP CONSTRAINT IF EXISTS check_coins_positive');
  await client.query('DROP INDEX IF EXISTS idx_post_comments_user_id');
  await client.query('DROP INDEX IF EXISTS idx_saved_posts_post_id');
  await client.query('DROP INDEX IF EXISTS idx_call_bookings_user_id');
  await client.query('DROP INDEX IF EXISTS idx_refresh_tokens_user_id');
  await client.query('DROP INDEX IF EXISTS idx_activity_logs_user_id');
  await client.query('DROP INDEX IF EXISTS idx_crop_disease_history_user_id');
  await client.query('DROP INDEX IF EXISTS idx_shop_products_shop_id');
  await client.query('DROP INDEX IF EXISTS idx_user_crop_schedules_user_id');
  await client.query('DROP INDEX IF EXISTS idx_user_crop_schedules_crop_id');
  await client.query('DROP INDEX IF EXISTS idx_dashboard_impressions_user_id');
  await client.query('DROP INDEX IF EXISTS idx_shop_coin_claims_user_id');
  await client.query('DROP INDEX IF EXISTS idx_shop_coin_claims_shop_id');
};
