/**
 * Add B-Tree spatial/composite indexes to latitude and longitude columns
 * This will improve proximity-based queries (e.g. nearby posts, nearby farmers).
 */

const up = async (pool) => {
  // Check if columns exist before adding indexes
  const checkQuery = `
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name='users' and column_name='latitude';
  `;
  const res = await pool.query(checkQuery);

  if (res.rows.length > 0) {
    console.log('Adding composite index for user locations...');
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_users_location 
      ON users (latitude, longitude)
      WHERE latitude IS NOT NULL AND longitude IS NOT NULL;
    `);
  }

  // Same for posts if they have latitude/longitude or village/state
  const postCheckQuery = `
    SELECT column_name 
    FROM information_schema.columns 
    WHERE table_name='posts' and column_name='village';
  `;
  const postRes = await pool.query(postCheckQuery);

  if (postRes.rows.length > 0) {
    console.log('Adding index for post locations...');
    await pool.query(`
      CREATE INDEX IF NOT EXISTS idx_posts_village_state 
      ON posts (state, village);
    `);
  }
};

const down = async (pool) => {
  await pool.query('DROP INDEX IF EXISTS idx_users_location;');
  await pool.query('DROP INDEX IF EXISTS idx_posts_village_state;');
};

module.exports = {
  up,
  down,
};
