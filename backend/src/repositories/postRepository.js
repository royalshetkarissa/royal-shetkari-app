const pool = require('../config/db');

const DATE_INTERVALS = {
  today: '1 day',
  week: '7 days',
  month: '30 days',
};

const SORT_ORDER_BY = {
  likes: 'p.likes_count DESC, p.created_at DESC',
  views: 'p.views_count DESC, p.created_at DESC',
  price_asc: 'p.price ASC, p.created_at DESC',
  price_desc: 'p.price DESC, p.created_at DESC',
};

function buildDistanceSelect(userLat, userLng, radius_km, state) {
  if (userLat && userLng && radius_km) {
    const distanceClause = `, (6371 * acos(cos(radians($${state.paramIndex})) * cos(radians(p.latitude)) * cos(radians(p.longitude) - radians($${state.paramIndex + 1})) + sin(radians($${state.paramIndex})) * sin(radians(p.latitude)))) AS distance`;
    state.params.push(userLat, userLng);
    state.paramIndex += 2;
    return distanceClause;
  }
  return '';
}

function buildDateFilter(dateFilter) {
  const interval = DATE_INTERVALS[dateFilter];
  if (interval) {
    return ` AND p.created_at >= NOW() - INTERVAL '${interval}'`;
  }
  return '';
}

function buildOrderBy(sortBy, hasDistance) {
  if (SORT_ORDER_BY[sortBy]) {
    return SORT_ORDER_BY[sortBy];
  }
  if (hasDistance) {
    return 'distance ASC';
  }
  return 'p.created_at DESC';
}

function appendFilters(query, filters, state) {
  const {
    category,
    animal_type,
    minPrice,
    maxPrice,
    radius_km,
    userLat,
    userLng,
    search,
    hasImages,
    dateFilter,
  } = filters;

  let updatedQuery = query;

  if (category && category !== 'all') {
    updatedQuery += ` AND p.category = $${state.paramIndex}`;
    state.params.push(category);
    state.paramIndex++;
  }

  if (animal_type) {
    updatedQuery += ` AND p.animal_type = $${state.paramIndex}`;
    state.params.push(animal_type);
    state.paramIndex++;
  }

  if (minPrice !== undefined) {
    updatedQuery += ` AND p.price >= $${state.paramIndex}`;
    state.params.push(minPrice);
    state.paramIndex++;
  }

  if (maxPrice !== undefined) {
    updatedQuery += ` AND p.price <= $${state.paramIndex}`;
    state.params.push(maxPrice);
    state.paramIndex++;
  }

  if (userLat && userLng && radius_km) {
    updatedQuery += ` AND (6371 * acos(cos(radians($1)) * cos(radians(p.latitude)) * cos(radians(p.longitude) - radians($2)) + sin(radians($1)) * sin(radians(p.latitude)))) <= $${state.paramIndex}`;
    state.params.push(radius_km);
    state.paramIndex++;
  }

  if (search) {
    updatedQuery += ` AND (p.title ILIKE $${state.paramIndex} OR p.description ILIKE $${state.paramIndex} OR p.location ILIKE $${state.paramIndex})`;
    state.params.push(`%${search}%`);
    state.paramIndex++;
  }

  if (hasImages === 'true' || hasImages === true) {
    updatedQuery += ` AND p.image_url IS NOT NULL AND p.image_url != ''`;
  }

  updatedQuery += buildDateFilter(dateFilter);

  return updatedQuery;
}

class PostRepository {
  async create(data) {
    const {
      userId,
      category,
      title,
      description,
      price,
      location,
      contact_mobile,
      images,
      image_url,
      latitude,
      longitude,
      animal_type,
      lactation,
      milk_per_day,
    } = data;
    const result = await pool.queryWithRetry(
      `INSERT INTO posts (user_id, category, title, description, price, location, contact_mobile, images, image_url, latitude, longitude, animal_type, lactation, milk_per_day) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) RETURNING *`,
      [
        userId,
        category,
        title,
        description,
        price || null,
        location,
        contact_mobile,
        JSON.stringify(images),
        image_url,
        latitude || null,
        longitude || null,
        animal_type || null,
        lactation || null,
        milk_per_day || null,
      ]
    );
    return result.rows[0];
  }

  async findAll(filters) {
    const { radius_km, userLat, userLng, sortBy } = filters || {};

    const state = { params: [], paramIndex: 1 };

    let selectClause = `SELECT p.*, u.full_name as farmer_name, u.village`;
    const distanceClause = buildDistanceSelect(userLat, userLng, radius_km, state);
    selectClause += distanceClause;

    let query = `
      ${selectClause}
      FROM posts p
      JOIN users u ON p.user_id = u.id
      WHERE p.status = 'active'
    `;

    query = appendFilters(query, filters || {}, state);

    const hasDistance = !!(userLat && userLng && radius_km);
    const orderBy = buildOrderBy(sortBy, hasDistance);
    query += ` ORDER BY ${orderBy}`;

    const result = await pool.queryWithRetry(query, state.params);
    return result.rows;
  }

  async findById(id) {
    const result = await pool.queryWithRetry(
      `
      SELECT p.*, u.full_name as farmer_name, u.village, u.profile_photo_url,
      (SELECT COUNT(*) FROM post_likes WHERE post_id = p.id) as total_likes,
      (SELECT COUNT(*) FROM post_comments WHERE post_id = p.id) as total_comments,
      (SELECT COUNT(*) FROM saved_posts WHERE post_id = p.id) as total_saves
      FROM posts p JOIN users u ON p.user_id = u.id 
      WHERE p.id = $1`,
      [id]
    );
    return result.rows[0];
  }

  async incrementViews(id) {
    await pool.queryWithRetry('UPDATE posts SET views_count = views_count + 1 WHERE id = $1', [id]);
  }

  async incrementWpClicks(id) {
    await pool.queryWithRetry('UPDATE posts SET wp_clicks = wp_clicks + 1 WHERE id = $1', [id]);
  }

  async incrementCallClicks(id) {
    await pool.queryWithRetry('UPDATE posts SET call_clicks = call_clicks + 1 WHERE id = $1', [id]);
  }

  async findLike(userId, postId) {
    const result = await pool.queryWithRetry(
      'SELECT * FROM post_likes WHERE user_id = $1 AND post_id = $2',
      [userId, postId]
    );
    return result.rows[0];
  }

  async addLike(userId, postId) {
    await pool.queryWithRetry('INSERT INTO post_likes (user_id, post_id) VALUES ($1, $2)', [
      userId,
      postId,
    ]);
    await pool.queryWithRetry('UPDATE posts SET likes_count = likes_count + 1 WHERE id = $1', [
      postId,
    ]);
  }

  async removeLike(userId, postId) {
    await pool.queryWithRetry('DELETE FROM post_likes WHERE user_id = $1 AND post_id = $2', [
      userId,
      postId,
    ]);
    await pool.queryWithRetry('UPDATE posts SET likes_count = likes_count - 1 WHERE id = $1', [
      postId,
    ]);
  }

  async findSave(userId, postId) {
    const result = await pool.queryWithRetry(
      'SELECT * FROM saved_posts WHERE user_id = $1 AND post_id = $2',
      [userId, postId]
    );
    return result.rows[0];
  }

  async addSave(userId, postId) {
    await pool.queryWithRetry('INSERT INTO saved_posts (user_id, post_id) VALUES ($1, $2)', [
      userId,
      postId,
    ]);
  }

  async removeSave(userId, postId) {
    await pool.queryWithRetry('DELETE FROM saved_posts WHERE user_id = $1 AND post_id = $2', [
      userId,
      postId,
    ]);
  }

  async getComments(postId) {
    const result = await pool.queryWithRetry(
      `
      SELECT c.*, u.full_name, u.profile_photo_url 
      FROM post_comments c JOIN users u ON c.user_id = u.id 
      WHERE c.post_id = $1 ORDER BY c.created_at DESC`,
      [postId]
    );
    return result.rows;
  }

  async addComment(userId, postId, content) {
    const result = await pool.queryWithRetry(
      'INSERT INTO post_comments (user_id, post_id, content) VALUES ($1, $2, $3) RETURNING *',
      [userId, postId, content]
    );
    return result.rows[0];
  }

  async updateStatus(postId, userId, userMobile, status) {
    if (status === 'deleted') {
      // 1. Fetch current post details
      const postRes = await pool.queryWithRetry(
        'SELECT * FROM posts WHERE id = $1 AND (user_id = $2 OR contact_mobile = $3)',
        [postId, userId, userMobile]
      );
      const post = postRes.rows[0];

      if (post) {
        // 2. Fetch comments with commenter user details
        const commentsRes = await pool.queryWithRetry(
          `SELECT c.content, c.created_at, u.id as user_id, u.full_name, u.mobile 
           FROM post_comments c 
           JOIN users u ON c.user_id = u.id 
           WHERE c.post_id = $1 ORDER BY c.created_at DESC`,
          [postId]
        );
        const comments = commentsRes.rows;

        // 3. Fetch likes with user details (checking if created_at exists dynamically to prevent error)
        const colRes = await pool.queryWithRetry(
          `SELECT column_name FROM information_schema.columns WHERE table_name='post_likes' AND column_name='created_at'`
        );
        const likesQuery =
          colRes.rows.length > 0
            ? `SELECT l.created_at, u.id as user_id, u.full_name, u.mobile FROM post_likes l JOIN users u ON l.user_id = u.id WHERE l.post_id = $1`
            : `SELECT NOW() as created_at, u.id as user_id, u.full_name, u.mobile FROM post_likes l JOIN users u ON l.user_id = u.id WHERE l.post_id = $1`;

        const likesRes = await pool.queryWithRetry(likesQuery, [postId]);
        const likes = likesRes.rows;

        // 4. Fetch saves with user details
        const savesRes = await pool.queryWithRetry(
          `SELECT s.created_at, u.id as user_id, u.full_name, u.mobile 
           FROM saved_posts s 
           JOIN users u ON s.user_id = u.id 
           WHERE s.post_id = $1 ORDER BY s.created_at DESC`,
          [postId]
        );
        const saves = savesRes.rows;

        // 5. Insert history record
        await pool.queryWithRetry(
          `INSERT INTO deleted_posts_history (
            post_id, user_id, category, title, description, price, old_price, location, 
            latitude, longitude, animal_type, lactation, milk_per_day, wp_clicks, call_clicks, 
            contact_mobile, images, image_url, likes_count, views_count, status, post_created_at, 
            deleted_at, comments, likes, saves
          ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, NOW(), $23, $24, $25)`,
          [
            post.id,
            post.user_id,
            post.category,
            post.title,
            post.description,
            post.price,
            post.old_price,
            post.location,
            post.latitude,
            post.longitude,
            post.animal_type,
            post.lactation,
            post.milk_per_day,
            post.wp_clicks,
            post.call_clicks,
            post.contact_mobile,
            JSON.stringify(post.images),
            post.image_url,
            post.likes_count,
            post.views_count,
            'deleted',
            post.created_at,
            JSON.stringify(comments),
            JSON.stringify(likes),
            JSON.stringify(saves),
          ]
        );
      }

      // Update status and set deleted_at to NOW()
      const result = await pool.queryWithRetry(
        'UPDATE posts SET status = $1, deleted_at = NOW() WHERE id = $2 AND (user_id = $3 OR contact_mobile = $4) RETURNING *',
        [status, postId, userId, userMobile]
      );
      return result.rows[0];
    } else {
      const result = await pool.queryWithRetry(
        'UPDATE posts SET status = $1 WHERE id = $2 AND (user_id = $3 OR contact_mobile = $4) RETURNING *',
        [status, postId, userId, userMobile]
      );
      return result.rows[0];
    }
  }

  async update(postId, userId, userMobile, data) {
    const {
      category,
      title,
      description,
      price,
      location,
      contact_mobile,
      oldPrice,
      latitude,
      longitude,
      animal_type,
      lactation,
      milk_per_day,
    } = data;
    const result = await pool.queryWithRetry(
      `UPDATE posts SET category = $1, title = $2, description = $3, price = $4, location = $5, 
       contact_mobile = $6, edit_count = edit_count + 1, old_price = $7, status = 'active',
       latitude = COALESCE($8, latitude), longitude = COALESCE($9, longitude), animal_type = $10, lactation = $11, milk_per_day = $12
       WHERE id = $13 AND (user_id = $14 OR contact_mobile = $15) RETURNING *`,
      [
        category,
        title,
        description,
        price,
        location,
        contact_mobile,
        oldPrice,
        latitude || null,
        longitude || null,
        animal_type || null,
        lactation || null,
        milk_per_day || null,
        postId,
        userId,
        userMobile,
      ]
    );
    return result.rows[0];
  }

  async findUserPosts(userId, userMobile) {
    const result = await pool.queryWithRetry(
      `SELECT * FROM posts WHERE user_id = $1 OR contact_mobile = $2 ORDER BY created_at DESC`,
      [userId, userMobile]
    );
    return result.rows;
  }

  async getUserSocialStats(userId) {
    const result = await pool.queryWithRetry(
      `
      SELECT COALESCE(SUM(likes_count), 0) as total_likes, COALESCE(SUM(views_count), 0) as total_views 
      FROM posts WHERE user_id = $1`,
      [userId]
    );
    return result.rows[0];
  }

  async getSavedPosts(userId) {
    const result = await pool.queryWithRetry(
      `
      SELECT p.*, u.full_name as farmer_name 
      FROM saved_posts s 
      JOIN posts p ON s.post_id = p.id 
      JOIN users u ON p.user_id = u.id 
      WHERE s.user_id = $1 ORDER BY s.created_at DESC`,
      [userId]
    );
    return result.rows;
  }
}

module.exports = new PostRepository();
