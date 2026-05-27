// Inject default test environment variables if they are not already set
process.env.NODE_ENV = 'test';
process.env.JWT_SECRET = process.env.JWT_SECRET || 'mock_secret_key_for_testing_purposes_only';
process.env.DB_SSL_REJECT_UNAUTHORIZED = process.env.DB_SSL_REJECT_UNAUTHORIZED || 'false';

// Mock ioredis
jest.mock('ioredis', () => {
  const EventEmitter = require('events');
  class MockRedis extends EventEmitter {
    constructor() {
      super();
      process.nextTick(() => {
        this.emit('connect');
      });
    }

    on(event, handler) {
      if (event === 'connect') {
        process.nextTick(handler);
      }
      super.on(event, handler);
      return this;
    }

    async get() { return null; }
    async set() { return 'OK'; }
    async del() { return 1; }
    async keys() { return []; }
    async quit() { return 'OK'; }
    async disconnect() {}
    async ping() { return 'PONG'; }
  }
  return MockRedis;
});

// Mock bullmq
jest.mock('bullmq', () => {
  return {
    Queue: jest.fn().mockImplementation(() => ({
      add: jest.fn().mockResolvedValue({ id: 'mock-job-id' }),
      close: jest.fn().mockResolvedValue(),
    })),
    Worker: jest.fn().mockImplementation(() => ({
      on: jest.fn(),
      close: jest.fn().mockResolvedValue(),
    })),
  };
});

const migrationRunner = require('../src/utils/migrationRunner');

beforeAll(async () => {
  try {
    await migrationRunner.up();
  } catch (err) {
    console.error('Failed to auto-run migrations during Jest setup:', err);
    throw err;
  }
});

afterAll(async () => {
  const pool = require('../src/config/db');
  if (pool && !pool._ending) {
    try {
      await pool.end();
    } catch (err) {
      if (!err.message.includes('Called end on pool more than once')) {
        throw err;
      }
    }
  }
});
