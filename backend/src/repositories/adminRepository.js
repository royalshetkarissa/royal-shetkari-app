const pool = require('../config/db');

class AdminRepository {
  async getAllPosts() {
    const result = await pool.query(`
      SELECT p.*, u.full_name as farmer_name, u.mobile as farmer_mobile, u.village 
      FROM posts p JOIN users u ON p.user_id = u.id 
      ORDER BY p.created_at DESC`);
    return result.rows;
  }

  async getAllUsers() {
    const result = await pool.query(`
      SELECT u.id, u.full_name, u.mobile, u.village, u.app_opens, u.last_activity,
             (SELECT COUNT(*) FROM posts WHERE user_id = u.id) as total_posts,
             (SELECT COUNT(*) FROM call_bookings WHERE user_id = u.id) as total_bookings
      FROM users u ORDER BY u.last_activity DESC NULLS LAST`);
    return result.rows;
  }

  async updateUserAccess(targetUserId, role, permissions, isAdmin) {
    await pool.query(
      'UPDATE users SET role = $1, permissions = $2, is_admin = $3 WHERE id = $4',
      [role, JSON.stringify(permissions), isAdmin, targetUserId]
    );
  }

  async getTopCommenters() {
    const result = await pool.query(`
      SELECT u.full_name, u.mobile, COUNT(c.id) as comment_count 
      FROM users u JOIN post_comments c ON u.id = c.user_id 
      GROUP BY u.id ORDER BY comment_count DESC LIMIT 10`);
    return result.rows;
  }

  async getUserById(id) {
    const result = await pool.query('SELECT full_name, mobile FROM users WHERE id = $1', [id]);
    return result.rows[0];
  }

  async deleteUser(id) {
    await pool.query('DELETE FROM users WHERE id = $1', [id]);
  }

  async getPostById(id) {
    const result = await pool.query('SELECT title FROM posts WHERE id = $1', [id]);
    return result.rows[0];
  }

  async deletePost(id) {
    await pool.query('DELETE FROM posts WHERE id = $1', [id]);
  }

  async getCommentById(id) {
    const result = await pool.query('SELECT content FROM post_comments WHERE id = $1', [id]);
    return result.rows[0];
  }

  async deleteComment(id) {
    await pool.query('DELETE FROM post_comments WHERE id = $1', [id]);
  }

  async getModerationLogs() {
    const result = await pool.query(`
      SELECT l.*, u.full_name as admin_name 
      FROM activity_logs l JOIN users u ON l.user_id = u.id 
      WHERE l.action_type LIKE 'DELETE_%' OR l.action_type = 'UPDATE_USER_ACCESS'
      ORDER BY l.created_at DESC`);
    return result.rows;
  }

  async getUserFullProfile(id) {
    const posts = await pool.query('SELECT * FROM posts WHERE user_id = $1 ORDER BY created_at DESC', [id]);
    const bookings = await pool.query('SELECT * FROM call_bookings WHERE user_id = $1 ORDER BY created_at DESC', [id]);
    const user = await pool.query('SELECT * FROM users WHERE id = $1', [id]);
    return { user: user.rows[0], posts: posts.rows, bookings: bookings.rows };
  }

  async getPostAuditHistory(id) {
    const history = await pool.query(`
      SELECT l.*, u.full_name as actor_name 
      FROM activity_logs l JOIN users u ON l.user_id = u.id 
      WHERE l.resource_id = $1 AND l.resource_type = 'post' 
      ORDER BY l.created_at DESC`, [id]);
    
    const post = await pool.query(`
      SELECT p.*, u.full_name as author_name
      FROM posts p JOIN users u ON p.user_id = u.id 
      WHERE p.id = $1`, [id]);

    const likers = await pool.query(`
      SELECT u.full_name, u.mobile FROM post_likes l JOIN users u ON l.user_id = u.id WHERE l.post_id = $1`, [id]);

    const savers = await pool.query(`
      SELECT u.full_name FROM saved_posts s JOIN users u ON s.user_id = u.id WHERE s.post_id = $1`, [id]);

    const comments = await pool.query(`
      SELECT c.*, u.full_name FROM post_comments c JOIN users u ON c.user_id = u.id WHERE c.post_id = $1 ORDER BY c.created_at DESC`, [id]);
    
    return {
      history: history.rows,
      post: post.rows[0],
      likers: likers.rows,
      savers: savers.rows,
      comments: comments.rows
    };
  }

  async getUserComments(userId) {
    const result = await pool.query(`
      SELECT c.*, p.title as post_title, p.image_url as post_photo, p.id as post_id
      FROM post_comments c 
      JOIN posts p ON c.post_id = p.id 
      WHERE c.user_id = $1 ORDER BY c.created_at DESC`, [userId]);
    return result.rows;
  }
}

module.exports = new AdminRepository();
