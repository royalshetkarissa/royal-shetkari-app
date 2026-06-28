-- Royal Shetkari PostgreSQL schema
-- Run with: psql -U postgres -f database/schema.sql

-- USERS TABLE
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  full_name VARCHAR(120) NOT NULL,
  mobile VARCHAR(15) NOT NULL UNIQUE,
  email VARCHAR(160) UNIQUE,
  password TEXT NOT NULL, -- Matched to AuthService
  village VARCHAR(120),
  state VARCHAR(120),
  pincode VARCHAR(10),
  latitude NUMERIC,
  longitude NUMERIC,
  current_location VARCHAR(255),
  is_admin BOOLEAN DEFAULT FALSE,
  is_verified BOOLEAN DEFAULT FALSE, -- Added for OTP flow
  role VARCHAR(20) DEFAULT 'user',
  permissions JSONB DEFAULT '{}',
  profile_photo_url TEXT,
  app_opens INTEGER DEFAULT 0, -- Added for analytics
  last_activity TIMESTAMPTZ, -- Added for session tracking
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- POSTS TABLE
CREATE TABLE IF NOT EXISTS posts (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  category VARCHAR(50),
  title VARCHAR(150),
  description TEXT,
  price NUMERIC,
  old_price NUMERIC,
  location VARCHAR(150),
  latitude NUMERIC,
  longitude NUMERIC,
  animal_type VARCHAR(50),
  lactation VARCHAR(50),
  milk_per_day NUMERIC,
  wp_clicks INTEGER DEFAULT 0,
  call_clicks INTEGER DEFAULT 0,
  contact_mobile VARCHAR(15),
  images JSONB DEFAULT '[]',
  image_url TEXT,
  likes_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  edit_count INTEGER DEFAULT 0,
  status VARCHAR(20) DEFAULT 'active',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- COMMENTS
CREATE TABLE IF NOT EXISTS post_comments (
  id SERIAL PRIMARY KEY,
  post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  content TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- LIKES
CREATE TABLE IF NOT EXISTS post_likes (
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
  PRIMARY KEY (user_id, post_id)
);

-- SAVED POSTS
CREATE TABLE IF NOT EXISTS saved_posts (
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  post_id INTEGER REFERENCES posts(id) ON DELETE CASCADE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  PRIMARY KEY (user_id, post_id)
);

-- CALL BOOKINGS
CREATE TABLE IF NOT EXISTS call_bookings (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  booking_date DATE,
  booking_time TIME,
  help_type VARCHAR(50),
  mobile VARCHAR(15),
  status VARCHAR(20) DEFAULT 'pending',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- REFRESH TOKENS
CREATE TABLE IF NOT EXISTS refresh_tokens (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  token TEXT UNIQUE NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- ACTIVITY LOGS
CREATE TABLE IF NOT EXISTS activity_logs (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE SET NULL,
  action_type VARCHAR(50),
  resource_type VARCHAR(20),
  resource_id INTEGER,
  details JSONB DEFAULT '{}',
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- OTP TABLE
CREATE TABLE IF NOT EXISTS otps (
  id SERIAL PRIMARY KEY,
  mobile VARCHAR(15) NOT NULL,
  otp VARCHAR(6) NOT NULL,
  expires_at TIMESTAMPTZ NOT NULL,
  is_used BOOLEAN DEFAULT FALSE,
  attempts INTEGER DEFAULT 0,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crop Disease History Table
CREATE TABLE IF NOT EXISTS crop_disease_history (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  image_url TEXT,
  disease_name VARCHAR(150),
  chemical_solution TEXT,
  organic_solution TEXT,
  is_deleted_by_user BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shops Table
CREATE TABLE IF NOT EXISTS shops (
  id SERIAL PRIMARY KEY,
  name VARCHAR(150),
  location_name VARCHAR(150),
  latitude NUMERIC,
  longitude NUMERIC,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Shop Products Table
CREATE TABLE IF NOT EXISTS shop_products (
  id SERIAL PRIMARY KEY,
  shop_id INTEGER REFERENCES shops(id) ON DELETE CASCADE,
  name VARCHAR(150),
  image_url TEXT,
  price NUMERIC,
  is_organic BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Crop Time Tables (Global Templates)
CREATE TABLE IF NOT EXISTS crop_time_tables (
  id SERIAL PRIMARY KEY,
  crop_name VARCHAR(100),
  schedule JSONB,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- User Crop Schedules (Active timetables for a user)
CREATE TABLE IF NOT EXISTS user_crop_schedules (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  crop_time_table_id INTEGER REFERENCES crop_time_tables(id) ON DELETE CASCADE,
  planting_date DATE,
  is_active BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

-- Dashboard Card Impressions/Analytics Table
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
