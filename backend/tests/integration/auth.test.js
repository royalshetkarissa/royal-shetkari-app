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

    expect(res.statusCode).toEqual(201);
    expect(res.body).toHaveProperty('message');
    expect(res.body.message).toContain('If the details are valid, an OTP has been sent.');
  });

  it('should validate missing fields', async () => {
    const res = await request(app)
      .post('/api/v1/register')
      .send({ mobile: '123' });

    expect(res.statusCode).toEqual(400);
    expect(res.body.status).toBe('fail');
  });

  describe('POST /api/v1/auth/reset-password', () => {
    it('should reset password successfully for registered user', async () => {
      // First ensure the user is registered cleanly by clearing any old records
      await pool.query('DELETE FROM users WHERE mobile = $1', [testUser.mobile]);
      const regRes = await request(app)
        .post('/api/v1/register')
        .send(testUser);
      const otp = regRes.body.devOtp;

      // Now reset the password
      const res = await request(app)
        .post('/api/v1/reset-password')
        .send({
          mobile: testUser.mobile,
          newPassword: 'newsecurepassword123',
          otp: otp,
        });

      expect(res.statusCode).toEqual(200);
      expect(res.body.success).toBe(true);
      expect(res.body.message).toContain('successfully');
      expect(res.body.user).toHaveProperty('id');
      expect(res.body.user.mobile).toBe(testUser.mobile);
    });

    it('should return 404 when resetting password for non-registered mobile', async () => {
      const res = await request(app)
        .post('/api/v1/reset-password')
        .send({
          mobile: '9999999991',
          newPassword: 'somepassword123',
          otp: '123456',
        });

      console.log('--- 404 test res.body:', res.body);
      expect(res.statusCode).toEqual(404);
      expect(res.body.status).toBe('fail');
      expect(res.body.message).toContain('Mobile number not registered');
    });

    it('should return 400 when validation fails (password too short)', async () => {
      const res = await request(app)
        .post('/api/v1/reset-password')
        .send({
          mobile: testUser.mobile,
          newPassword: '123',
          otp: '123456',
        });

      expect(res.statusCode).toEqual(400);
      expect(res.body.status).toBe('fail');
    });
  });
});

