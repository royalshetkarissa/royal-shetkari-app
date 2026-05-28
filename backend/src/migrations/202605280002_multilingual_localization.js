/**
 * Migration: 202605280002_multilingual_localization
 * Purpose: Create schema tables for localization (languages, keys, and translations) and seed basic configurations.
 */
exports.up = async (client) => {
  await client.query(`
    -- 1. Create languages table
    CREATE TABLE IF NOT EXISTS languages (
      code VARCHAR(10) PRIMARY KEY,
      name VARCHAR(50) NOT NULL,
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- 2. Create translation_keys table
    CREATE TABLE IF NOT EXISTS translation_keys (
      id SERIAL PRIMARY KEY,
      key VARCHAR(100) UNIQUE NOT NULL,
      section VARCHAR(50) DEFAULT 'general',
      description TEXT,
      created_at TIMESTAMPTZ DEFAULT NOW()
    );

    -- 3. Create translations table
    CREATE TABLE IF NOT EXISTS translations (
      id SERIAL PRIMARY KEY,
      key_id INTEGER REFERENCES translation_keys(id) ON DELETE CASCADE,
      language_code VARCHAR(10) REFERENCES languages(code) ON DELETE CASCADE,
      value TEXT NOT NULL,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      updated_at TIMESTAMPTZ DEFAULT NOW(),
      CONSTRAINT unique_key_language UNIQUE (key_id, language_code)
    );

    -- 4. Create index on translations for fast lookups
    CREATE INDEX IF NOT EXISTS idx_translations_lang_key ON translations(language_code);

    -- 5. Seed languages
    INSERT INTO languages (code, name, is_active) VALUES
      ('en', 'English', true),
      ('hi', 'हिंदी', true),
      ('mr', 'मराठी', true),
      ('ta', 'தமிழ்', true),
      ('gu', 'ગુજરાતી', true)
    ON CONFLICT (code) DO UPDATE SET name = EXCLUDED.name, is_active = EXCLUDED.is_active;

    -- 6. Seed translation keys
    INSERT INTO translation_keys (key, section, description) VALUES
      ('welcome', 'auth', 'Welcome title on start screen'),
      ('next', 'general', 'Next button text'),
      ('choose_language', 'auth', 'Label to prompt language selection'),
      ('home', 'navigation', 'Home navigation item'),
      ('profile', 'navigation', 'Profile navigation item'),
      ('community', 'navigation', 'Community navigation item')
    ON CONFLICT (key) DO NOTHING;
  `);

  // 7. Seed translation values dynamically
  const seeds = [
    { key: 'welcome', lang: 'en', val: 'Welcome' },
    { key: 'welcome', lang: 'hi', val: 'स्वागत है' },
    { key: 'welcome', lang: 'mr', val: 'स्वागत आहे' },
    { key: 'welcome', lang: 'ta', val: 'வரவேற்கிறோம்' },
    { key: 'welcome', lang: 'gu', val: 'સ્વાગત છે' },

    { key: 'next', lang: 'en', val: 'Next' },
    { key: 'next', lang: 'hi', val: 'आगे' },
    { key: 'next', lang: 'mr', val: 'पुढे' },
    { key: 'next', lang: 'ta', val: 'அடுத்து' },
    { key: 'next', lang: 'gu', val: 'આગળ' },

    { key: 'choose_language', lang: 'en', val: 'Choose Language' },
    { key: 'choose_language', lang: 'hi', val: 'भाषा चुनें' },
    { key: 'choose_language', lang: 'mr', val: 'भाषा निवडा' },
    { key: 'choose_language', lang: 'ta', val: 'மொழியைத் தேர்ந்தெடுக்கவும்' },
    { key: 'choose_language', lang: 'gu', val: 'ભાષા પસંદ કરો' },

    { key: 'home', lang: 'en', val: 'Home' },
    { key: 'home', lang: 'hi', val: 'होम' },
    { key: 'home', lang: 'mr', val: 'होम' },
    { key: 'home', lang: 'ta', val: 'முகப்பு' },
    { key: 'home', lang: 'gu', val: 'હોમ' },

    { key: 'profile', lang: 'en', val: 'Profile' },
    { key: 'profile', lang: 'hi', val: 'प्रोफ़ाइल' },
    { key: 'profile', lang: 'mr', val: 'प्रोफाइल' },
    { key: 'profile', lang: 'ta', val: 'சுயவிவரம்' },
    { key: 'profile', lang: 'gu', val: 'પ્રોફાઇલ' },

    { key: 'community', lang: 'en', val: 'Community' },
    { key: 'community', lang: 'hi', val: 'समुदाय' },
    { key: 'community', lang: 'mr', val: 'समुदाय' },
    { key: 'community', lang: 'ta', val: 'சமூகம்' },
    { key: 'community', lang: 'gu', val: 'સમુદાય' },
  ];

  for (const seed of seeds) {
    await client.query(
      `
      INSERT INTO translations (key_id, language_code, value)
      VALUES (
        (SELECT id FROM translation_keys WHERE key = $1),
        $2,
        $3
      )
      ON CONFLICT (key_id, language_code) DO UPDATE SET value = EXCLUDED.value;
    `,
      [seed.key, seed.lang, seed.val]
    );
  }
};

exports.down = async (client) => {
  await client.query(`
    DROP INDEX IF EXISTS idx_translations_lang_key;
    DROP TABLE IF EXISTS translations;
    DROP TABLE IF EXISTS translation_keys;
    DROP TABLE IF EXISTS languages;
  `);
};
