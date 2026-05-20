-- MIGRATION SCRIPT TO FIX SCHEMA ERRORS
-- Run with: psql -U postgres -d royal_shetkari_db -f database/migrate.sql

-- 1. FIX USERS TABLE COLUMNS
DO $$ 
BEGIN 
    -- Add is_verified if not exists
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='users' AND COLUMN_NAME='is_verified') THEN
        ALTER TABLE users ADD COLUMN is_verified BOOLEAN DEFAULT FALSE;
    END IF;

    -- Add app_opens if not exists
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='users' AND COLUMN_NAME='app_opens') THEN
        ALTER TABLE users ADD COLUMN app_opens INTEGER DEFAULT 0;
    END IF;

    -- Add last_activity if not exists
    IF NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='users' AND COLUMN_NAME='last_activity') THEN
        ALTER TABLE users ADD COLUMN last_activity TIMESTAMPTZ;
    END IF;

    -- Rename password_hash to password if password doesn't exist
    IF EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='users' AND COLUMN_NAME='password_hash') 
       AND NOT EXISTS (SELECT 1 FROM INFORMATION_SCHEMA.COLUMNS WHERE TABLE_NAME='users' AND COLUMN_NAME='password') THEN
        ALTER TABLE users RENAME COLUMN password_hash TO password;
    END IF;
END $$;

-- 2. ENSURE OTP TABLE EXISTS
CREATE TABLE IF NOT EXISTS otps (
  id SERIAL PRIMARY KEY,
  mobile VARCHAR(15) NOT NULL,
  otp VARCHAR(6) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  is_used BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. ENSURE REFRESH TOKENS TABLE EXISTS
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 4. ENSURE ACTIVITY LOGS TABLE EXISTS
CREATE TABLE IF NOT EXISTS activity_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  action_type VARCHAR(50),
  resource_type VARCHAR(20),
  resource_id INTEGER,
  details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 5. ENSURE DASHBOARD IMPRESSIONS TABLE EXISTS
CREATE TABLE IF NOT EXISTS dashboard_impressions (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  active_type VARCHAR(50) NOT NULL, -- 'animal_post', 'shop', 'organic_ad'
  active_id VARCHAR(100) NOT NULL, -- post ID, shop ID, or organic ad banner ID/type
  active_date DATE DEFAULT CURRENT_DATE,
  seen_count INTEGER DEFAULT 1,
  start_time TIMESTAMPTZ NOT NULL,
  end_time TIMESTAMPTZ NOT NULL,
  duration_seconds INTEGER NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);
