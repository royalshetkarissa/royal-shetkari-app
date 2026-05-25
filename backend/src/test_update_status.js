const pool = require('c:\\Users\\sai\\Desktop\\royal_shetkari_app\\backend\\src\\config\\db');

async function test() {
  try {
    const postId = 1; // target 'cow'
    const userId = 2; // owner of cow
    const status = 'deleted';

    console.log("Simulating delete of postId:", postId, "for userId:", userId);
    
    // 1. Fetch current post details
    const postRes = await pool.query(
      'SELECT * FROM posts WHERE id = $1 AND user_id = $2',
      [postId, userId]
    );
    const post = postRes.rows[0];
    console.log("Found post:", post ? post.title : "Not found");
    
    if (post) {
      // 2. Fetch comments with commenter user details
      const commentsRes = await pool.query(
        `SELECT c.content, c.created_at, u.id as user_id, u.full_name, u.mobile 
         FROM post_comments c 
         JOIN users u ON c.user_id = u.id 
         WHERE c.post_id = $1 ORDER BY c.created_at DESC`,
        [postId]
      );
      const comments = commentsRes.rows;
      console.log("Comments count:", comments.length);

      // 3. Fetch likes with user details (checking if created_at exists dynamically to prevent error)
      const colRes = await pool.query(
        `SELECT column_name FROM information_schema.columns WHERE table_name='post_likes' AND column_name='created_at'`
      );
      let likesQuery = colRes.rows.length > 0
        ? `SELECT l.created_at, u.id as user_id, u.full_name, u.mobile FROM post_likes l JOIN users u ON l.user_id = u.id WHERE l.post_id = $1`
        : `SELECT NOW() as created_at, u.id as user_id, u.full_name, u.mobile FROM post_likes l JOIN users u ON l.user_id = u.id WHERE l.post_id = $1`;
      
      const likesRes = await pool.query(likesQuery, [postId]);
      const likes = likesRes.rows;
      console.log("Likes count:", likes.length);

      // 4. Fetch saves with user details
      const savesRes = await pool.query(
        `SELECT s.created_at, u.id as user_id, u.full_name, u.mobile 
         FROM saved_posts s 
         JOIN users u ON s.user_id = u.id 
         WHERE s.post_id = $1 ORDER BY s.created_at DESC`,
        [postId]
      );
      const saves = savesRes.rows;
      console.log("Saves count:", saves.length);

      // 5. Insert history record
      console.log("Inserting deleted post history...");
      await pool.query(
        `INSERT INTO deleted_posts_history (
          post_id, user_id, category, title, description, price, old_price, location, 
          latitude, longitude, animal_type, lactation, milk_per_day, wp_clicks, call_clicks, 
          contact_mobile, images, image_url, likes_count, views_count, status, post_created_at, 
          deleted_at, comments, likes, saves
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, NOW(), $23, $24, $25)`,
        [
          post.id, post.user_id, post.category, post.title, post.description, post.price, post.old_price, post.location,
          post.latitude, post.longitude, post.animal_type, post.lactation, post.milk_per_day, post.wp_clicks, post.call_clicks,
          post.contact_mobile, JSON.stringify(post.images), post.image_url, post.likes_count, post.views_count, 'deleted', post.created_at,
          JSON.stringify(comments), JSON.stringify(likes), JSON.stringify(saves)
        ]
      );
      console.log("History inserted successfully!");
    }
    
    // Update status and set deleted_at to NOW()
    console.log("Updating post status to 'deleted' in posts table...");
    const result = await pool.query(
      "UPDATE posts SET status = $1, deleted_at = NOW() WHERE id = $2 AND user_id = $3 RETURNING *",
      [status, postId, userId]
    );
    console.log("Updated post result:", result.rows[0]);
  } catch (err) {
    console.error("DB Test Error:", err);
  } finally {
    pool.end();
  }
}

test();
