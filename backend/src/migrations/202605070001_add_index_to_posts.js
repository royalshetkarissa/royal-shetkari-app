/**
 * Sample Migration: Add index to posts category for performance.
 */
exports.up = async (client) => {
  await client.query('CREATE INDEX IF NOT EXISTS idx_posts_category ON posts(category)');
};

exports.down = async (client) => {
  await client.query('DROP INDEX IF EXISTS idx_posts_category');
};
