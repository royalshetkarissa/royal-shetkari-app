const helmet = require('helmet');
const rateLimit = require('express-rate-limit');
const RedisStore = require('rate-limit-redis').default;
const { connection: redisClient, isRedisConfigured } = require('../config/redis');
const env = require('../config/env');
const logger = require('../utils/logger');

// Check if we should use Redis or fall back to memory
const useRedis = isRedisConfigured && env.NODE_ENV !== 'test';
if (!useRedis) {
  logger.warn('⚠️ Rate limiter is running in MEMORY mode (Redis not configured or test environment). This will not work across multiple instances.');
}

const getStore = () => useRedis ? new RedisStore({ sendCommand: (...args) => redisClient.call(...args) }) : undefined;

/**
 * Configure Helmet security headers.
 */
exports.securityHeaders = helmet({
  contentSecurityPolicy:
    env.NODE_ENV === 'production'
      ? {
          directives: {
            defaultSrc: ["'self'"],
            scriptSrc: ["'self'"],
            styleSrc: ["'self'", "'unsafe-inline'"],
            imgSrc: ["'self'", 'data:', 'https:'],
            connectSrc: ["'self'", 'https:'],
          },
        }
      : false,
  crossOriginEmbedderPolicy: true,
  crossOriginOpenerPolicy: true,
  crossOriginResourcePolicy: { policy: 'cross-origin' },
  dnsPrefetchControl: { allow: false },
  frameguard: { action: 'deny' },
  hidePoweredBy: true,
  hsts: { maxAge: 31536000, includeSubDomains: true, preload: true },
  ieNoOpen: true,
  noSniff: true,
  originAgentCluster: true,
  permittedCrossDomainPolicies: { policy: 'none' },
  referrerPolicy: { policy: 'no-referrer' },
  xssFilter: true,
});

/**
 * General API Rate Limiter.
 */
exports.apiLimiter = rateLimit({
  store: getStore(),
  windowMs: 1 * 60 * 1000,
  max: 100,
  message: { status: 'fail', message: 'Too many requests. Please try again after a minute.' },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false },
});

/**
 * Authenticated Rate Limiter.
 */
exports.authenticatedLimiter = rateLimit({
  store: getStore(),
  windowMs: 1 * 60 * 1000,
  max: 1000,
  keyGenerator: (req) => req.userId || req.ip,
  message: { status: 'fail', message: 'High traffic detected. Please slow down.' },
  standardHeaders: true,
  legacyHeaders: false,
  validate: {
    xForwardedForHeader: false,
    keyGeneratorIpFallback: false,
  },
});

/**
 * Strict Auth Rate Limiter.
 */
exports.authLimiter = rateLimit({
  store: getStore(),
  windowMs: 60 * 60 * 1000,
  max: 10,
  message: { status: 'fail', message: 'Too many login attempts. Please try again after an hour.' },
  standardHeaders: true,
  legacyHeaders: false,
  validate: { xForwardedForHeader: false },
});
