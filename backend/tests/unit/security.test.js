const rateLimit = require('express-rate-limit');

describe('Security Middleware - Rate Limiter Store Configuration', () => {
  const originalEnv = process.env.NODE_ENV;

  beforeEach(() => {
    jest.resetModules();
  });

  afterEach(() => {
    process.env.NODE_ENV = originalEnv;
  });

  it('should use RedisStore when Redis is configured and NOT in test environment', () => {
    // Mock environment to be development (not test)
    process.env.NODE_ENV = 'development';

    // Mock redis configuration
    jest.mock('../../src/config/redis', () => ({
      connection: { call: jest.fn() },
      isRedisConfigured: true,
    }));

    // Mock logger to suppress warnings
    jest.mock('../../src/utils/logger', () => ({
      warn: jest.fn(),
      error: jest.fn(),
    }));

    // Spy on rate-limit-redis default constructor
    const mockRedisStore = jest.fn().mockImplementation(() => ({
      // dummy store implementation
      increment: jest.fn(),
      decrement: jest.fn(),
      resetKey: jest.fn(),
    }));
    jest.mock('rate-limit-redis', () => ({
      default: mockRedisStore,
    }));

    // Require the security module after setting up the mocks
    const security = require('../../src/middleware/security');

    // We have 3 limiters: apiLimiter, authenticatedLimiter, authLimiter.
    // They should all be using RedisStore. We check if mockRedisStore was called 3 times.
    expect(mockRedisStore).toHaveBeenCalledTimes(3);
  });

  it('should use undefined (fallback to memory) when in test environment', () => {
    process.env.NODE_ENV = 'test';

    jest.mock('../../src/config/redis', () => ({
      connection: { call: jest.fn() },
      isRedisConfigured: true,
    }));

    jest.mock('../../src/utils/logger', () => ({
      warn: jest.fn(),
      error: jest.fn(),
    }));

    const mockRedisStore = jest.fn().mockImplementation(() => ({
      increment: jest.fn(),
      decrement: jest.fn(),
      resetKey: jest.fn(),
    }));
    jest.mock('rate-limit-redis', () => ({
      default: mockRedisStore,
    }));

    require('../../src/middleware/security');

    // Should not instantiate RedisStore in test env
    expect(mockRedisStore).not.toHaveBeenCalled();
  });

  it('should use undefined and log warning when Redis is NOT configured', () => {
    process.env.NODE_ENV = 'development';

    jest.mock('../../src/config/redis', () => ({
      connection: { call: jest.fn() },
      isRedisConfigured: false,
    }));

    const mockLogger = {
      warn: jest.fn(),
      error: jest.fn(),
    };
    jest.mock('../../src/utils/logger', () => mockLogger);

    const mockRedisStore = jest.fn().mockImplementation(() => ({}));
    jest.mock('rate-limit-redis', () => ({
      default: mockRedisStore,
    }));

    require('../../src/middleware/security');

    // Should not instantiate RedisStore when not configured
    expect(mockRedisStore).not.toHaveBeenCalled();
    expect(mockLogger.warn).toHaveBeenCalledWith(expect.stringContaining('Rate limiter is running in MEMORY mode'));
  });
});
