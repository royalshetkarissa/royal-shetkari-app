const request = require('supertest');
const app = require('../../src/app');
const pool = require('../../src/config/db');

describe('Auth Integration Tests', () => {
  const testUser = {
    fullName: 'Test User',
    mobile: '1234567890',
    email: 'test@example.com',
    password: 'password123',
    village: 'Test Village'
  };

  beforeAll(async () => {
    // Cleanup test user if exists
    await pool.query('DELETE FROM users WHERE mobile = $1', [testUser.mobile]);
  });

  afterAll(async () => {
    // Cleanup test user
    await pool.query('DELETE FROM users WHERE mobile = $1', [testUser.mobile]);
  });

  it('should register a new user successfully', async () => {
    const res = await request(app)
      .post('/api/v1/register')
      .send(testUser);

    expect(res.statusCode).toEqual(201);
    expect(res.body.success).toBe(true);
    expect(res.body).toHaveProperty('devOtp');
    expect(res.body.mobile).toBe(testUser.mobile);
  });

  it('should return 400 for duplicate registration', async () => {
    const res = await request(app)
      .post('/api/v1/register')
      .send(testUser);

    expect(res.statusCode).toEqual(400);
    expect(res.body).toHaveProperty('message');
    expect(res.body.message).toContain('already registered');
  });

  it('should validate missing fields', async () => {
    const res = await request(app)
      .post('/api/v1/register')
      .send({ mobile: '123' });

    expect(res.statusCode).toEqual(400);
    expect(res.body.status).toBe('fail');
  });
});
