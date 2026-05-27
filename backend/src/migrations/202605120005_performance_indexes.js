/**
 * Migration: 202605120005_performance_indexes
 * Purpose: Ensure the app handles 100,000+ users with high-speed queries.
 */

exports.up = async (client) => {
  // Index for retrieving active journeys for a user
  await client.query(
    `CREATE INDEX IF NOT EXISTS idx_journeys_user_status ON user_crop_journeys(user_id, status);`
  );

  // Index for retrieving tasks for a journey
  await client.query(
    `CREATE INDEX IF NOT EXISTS idx_tasks_journey_id ON user_crop_tasks(user_crop_id);`
  );

  // Index for activity logging queries
  await client.query(
    `CREATE INDEX IF NOT EXISTS idx_activity_user_type ON activity_logs(user_id, action_type);`
  );

  // Index for user coin lookups
  await client.query(`CREATE INDEX IF NOT EXISTS idx_users_id_coins ON users(id) INCLUDE (coins);`);
};

exports.down = async (client) => {
  // Optional cleanup
};
