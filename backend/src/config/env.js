require('dotenv').config();
const { z } = require('zod');

/**
 * Validate environment variables at startup.
 */
const envSchema = z
  .object({
    PORT: z.string().default('5000'),
    NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
    JWT_SECRET: z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
    DATABASE_URL: z.string().optional(),
    DB_HOST: z.string().optional(),
    DB_USER: z.string().optional(),
    DB_PASSWORD: z.string().optional(),
    DB_NAME: z.string().optional(),
    DB_PORT: z.string().default('5432').optional(),
    ENABLE_TRACING: z.string().default('false'),
    OTEL_EXPORTER_OTLP_ENDPOINT: z.string().optional(),
    ALLOWED_ORIGINS: z.string().optional(),
    TWILIO_ACCOUNT_SID: z.string().optional(),
    TWILIO_AUTH_TOKEN: z.string().optional(),
    TWILIO_PHONE_NUMBER: z.string().optional(),
    SUPER_USER_MOBILE: z.string().default('8605889356'),
    DB_SSL_REJECT_UNAUTHORIZED: z.enum(['true', 'false']).default('true'),
  })
  .refine(
    (data) =>
      data.DATABASE_URL || (data.DB_HOST && data.DB_USER && data.DB_PASSWORD && data.DB_NAME),
    {
      message: 'Either DATABASE_URL or (DB_HOST, DB_USER, DB_PASSWORD, DB_NAME) must be provided',
      path: ['DATABASE_URL'],
    }
  );

const envParsed = envSchema.safeParse(process.env);

if (!envParsed.success) {
  console.error('❌ Invalid environment variables:', envParsed.error.format());
  process.exit(1);
}

const env = envParsed.data;

module.exports = {
  PORT: env.PORT,
  NODE_ENV: env.NODE_ENV,
  JWT_SECRET: env.JWT_SECRET,
  DATABASE_URL: env.DATABASE_URL,
  SUPER_USER_MOBILE: env.SUPER_USER_MOBILE,
  DB_SSL_REJECT_UNAUTHORIZED: env.DB_SSL_REJECT_UNAUTHORIZED === 'true',
  DB: {
    HOST: env.DB_HOST,
    USER: env.DB_USER,
    PASSWORD: env.DB_PASSWORD,
    NAME: env.DB_NAME,
    PORT: env.DB_PORT,
  },
  TWILIO: {
    SID: env.TWILIO_ACCOUNT_SID,
    TOKEN: env.TWILIO_AUTH_TOKEN,
    PHONE: env.TWILIO_PHONE_NUMBER,
  },
};
