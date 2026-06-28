const path = require('path');
require('dotenv').config();
if (process.env.NODE_ENV === 'test') {
  require('dotenv').config({ path: path.resolve(__dirname, '../../.env.test') });
}
const { z } = require('zod');
const crypto = require('crypto');

// Dynamic fallback for SUPER_ADMIN_PASSWORD in production to prevent startup crash if missing
if (process.env.NODE_ENV === 'production' && !process.env.SUPER_ADMIN_PASSWORD) {
  process.env.SUPER_ADMIN_PASSWORD = crypto.randomBytes(32).toString('hex');
  console.warn(`
========================================================================
⚠️  WARNING: SUPER_ADMIN_PASSWORD environment variable is missing!
A temporary password has been randomly generated for this session:
👉 SUPER_ADMIN_PASSWORD: ${process.env.SUPER_ADMIN_PASSWORD}
Please configure SUPER_ADMIN_PASSWORD in production environment variables.
========================================================================
  `);
}



// Warning for missing WhatsApp credentials
if (process.env.NODE_ENV === 'production' && (!process.env.META_WHATSAPP_TOKEN || !process.env.META_PHONE_ID)) {
  console.warn(`
========================================================================
⚠️  WARNING: META_WHATSAPP_TOKEN and/or META_PHONE_ID environment variables are missing!
WhatsApp OTP delivery will be disabled or fail. Please configure them in production.
========================================================================
  `);
}

/**
 * Validate environment variables at startup.
 */
const isTestObj = process.env.NODE_ENV === 'test';

const envSchema = z
  .object({
    PORT: z.string().default('5000'),
    NODE_ENV: z.enum(['development', 'production', 'test']).default('development'),
    JWT_SECRET: isTestObj
      ? z.string().default('mock_secret_key_for_testing_purposes_only')
      : z.string().min(32, 'JWT_SECRET must be at least 32 characters'),
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
    SUPER_ADMIN_NAME: z.string().default('System Admin'),
    SUPER_ADMIN_MOBILE: z.string().default('8605889356'),
    SUPER_ADMIN_EMAIL: z.string().default('admin@royalshetkari.com'),
    SUPER_ADMIN_PASSWORD: z.string().optional(),
    META_WHATSAPP_TOKEN: z.string().optional(),
    META_PHONE_ID: z.string().optional(),
  })
  .refine(
    (data) =>
      isTestObj ||
      data.DATABASE_URL ||
      (data.DB_HOST && data.DB_USER && data.DB_PASSWORD && data.DB_NAME),
    {
      message: 'Either DATABASE_URL or (DB_HOST, DB_USER, DB_PASSWORD, DB_NAME) must be provided',
      path: ['DATABASE_URL'],
    }
  )
  .refine(
    (data) => {
      if (data.NODE_ENV === 'production' && !data.SUPER_ADMIN_PASSWORD) {
        return false;
      }
      return true;
    },
    {
      message: 'SUPER_ADMIN_PASSWORD is required in production environment',
      path: ['SUPER_ADMIN_PASSWORD'],
    }
  )



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
  SUPER_ADMIN: {
    NAME: env.SUPER_ADMIN_NAME,
    MOBILE: env.SUPER_ADMIN_MOBILE,
    EMAIL: env.SUPER_ADMIN_EMAIL,
    PASSWORD: env.SUPER_ADMIN_PASSWORD,
  },
  META_WHATSAPP: {
    TOKEN: env.META_WHATSAPP_TOKEN,
    PHONE_ID: env.META_PHONE_ID,
  },
};
