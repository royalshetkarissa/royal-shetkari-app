const request = require('supertest');
const app = require('../../src/app');
const pool = require('../../src/config/db');
const jwtHelper = require('../../src/utils/jwtHelper');

describe('Posts Integration Tests', () => {
  let testUser;
  let token;
  let testPostId;

  beforeAll(async () => {
    // Clean tables to prevent constraint errors
    await pool.query('DELETE FROM post_comments');
    await pool.query('DELETE FROM post_likes');
    await pool.query('DELETE FROM saved_posts');
    await pool.query('DELETE FROM deleted_posts_history');
    await pool.query('DELETE FROM posts');
    await pool.query('DELETE FROM shops');
    await pool.query('DELETE FROM users');

    // Create a test user
    const userRes = await pool.query(
      `INSERT INTO users (full_name, mobile, password, village) 
       VALUES ('Post Author', '9876543219', 'hashedpassword', 'Test Village') RETURNING *`
    );
    testUser = userRes.rows[0];

    // Generate JWT token
    token = jwtHelper.signAccessToken({
      id: testUser.id,
      mobile: testUser.mobile,
      name: testUser.full_name,
      isAdmin: testUser.is_admin,
      role: testUser.role,
      permissions: testUser.permissions,
    });
  });

  afterAll(async () => {
    await pool.query('DELETE FROM post_comments');
    await pool.query('DELETE FROM post_likes');
    await pool.query('DELETE FROM saved_posts');
    await pool.query('DELETE FROM deleted_posts_history');
    await pool.query('DELETE FROM posts');
    await pool.query('DELETE FROM shops');
    await pool.query('DELETE FROM users');
  });

  it('should create a post successfully', async () => {
    const res = await request(app)
      .post('/api/v1/posts')
      .set('Authorization', `Bearer ${token}`)
      .send({
        category: 'animal',
        title: 'Cow for sale',
        description: 'Healthy Jersey cow, 12 liters milk/day',
        price: 55000,
        location: 'Pune',
        contact_number: '9876543219',
      });

    expect(res.statusCode).toEqual(201);
    expect(res.body.success).toBe(true);
    expect(res.body.post).toHaveProperty('id');
    expect(res.body.post.title).toBe('Cow for sale');
    testPostId = res.body.post.id;
  });

  it('should list active posts', async () => {
    const res = await request(app).get('/api/v1/posts');
    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.posts.length).toBeGreaterThan(0);
    expect(res.body.posts.find((p) => p.id === testPostId)).toBeDefined();
  });

  it('should soft delete the post successfully', async () => {
    const res = await request(app)
      .delete(`/api/v1/posts/${testPostId}`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.message).toContain('moved to history');

    // Verify it is no longer returned in active list
    const listRes = await request(app).get('/api/v1/posts');
    expect(listRes.body.posts.find((p) => p.id === testPostId)).toBeUndefined();

    // Verify it is saved in deleted_posts_history
    const historyRes = await pool.query(
      'SELECT * FROM deleted_posts_history WHERE post_id = $1',
      [testPostId]
    );
    expect(historyRes.rows.length).toEqual(1);
    expect(historyRes.rows[0].title).toBe('Cow for sale');
  });
});
