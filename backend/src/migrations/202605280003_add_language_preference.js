/**
 * Migration: 202605280003_add_language_preference
 * Purpose: Add language_preference field to users and create multilingual_content table.
 */
exports.up = async (client) => {
  await client.query(`
    ALTER TABLE users ADD COLUMN IF NOT EXISTS language_preference VARCHAR(10) DEFAULT 'en';
    
    CREATE TABLE IF NOT EXISTS multilingual_content (
      id SERIAL PRIMARY KEY,
      content_key VARCHAR(100) NOT NULL,
      language_code VARCHAR(10) NOT NULL,
      content TEXT,
      CONSTRAINT unique_content_key_lang UNIQUE (content_key, language_code)
    );
  `);
};

exports.down = async (client) => {
  await client.query(`
    ALTER TABLE users DROP COLUMN IF EXISTS language_preference;
    DROP TABLE IF EXISTS multilingual_content;
  `);
};
