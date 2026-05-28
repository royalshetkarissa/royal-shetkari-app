const pool = require('../config/db');
const { connection: redis } = require('../config/redis');
const logger = require('../utils/logger');

const CACHE_TTL = 3600; // 1 hour caching for translations
const REDIS_PREFIX = 'royal_shetkari:translations:';

// In-memory fallback cache if Redis is not connected
const localCache = new Map();

/**
 * Helper to check if Redis is connected and usable
 */
const isRedisConnected = () => {
  return redis && redis.status === 'ready';
};

/**
 * Fetch all translations for a given language code.
 * Optimized with Redis caching and in-memory cache fallback.
 */
async function getTranslations(langCode) {
  const cacheKey = `${REDIS_PREFIX}${langCode}`;

  // 1. Try fetching from Redis
  if (isRedisConnected()) {
    try {
      const cachedData = await redis.get(cacheKey);
      if (cachedData) {
        return JSON.parse(cachedData);
      }
    } catch (err) {
      logger.warn('Failed to read translations from Redis cache:', { error: err.message });
    }
  } else {
    // 2. Try fetching from Local Memory Cache
    if (localCache.has(langCode)) {
      const cached = localCache.get(langCode);
      if (Date.now() - cached.timestamp < CACHE_TTL * 1000) {
        return cached.data;
      }
    }
  }

  // 3. Database Query
  try {
    const result = await pool.query(
      `SELECT tk.key, t.value 
       FROM translations t 
       JOIN translation_keys tk ON t.key_id = tk.id 
       WHERE t.language_code = $1`,
      [langCode]
    );

    const translationsObj = {};
    for (const row of result.rows) {
      translationsObj[row.key] = row.value;
    }

    // 4. Save to Redis/Local Cache
    if (isRedisConnected()) {
      try {
        await redis.set(cacheKey, JSON.stringify(translationsObj), 'EX', CACHE_TTL);
      } catch (err) {
        logger.warn('Failed to save translations to Redis:', { error: err.message });
      }
    } else {
      localCache.set(langCode, {
        timestamp: Date.now(),
        data: translationsObj
      });
    }

    return translationsObj;
  } catch (err) {
    logger.error('Failed to fetch translations from database:', { error: err.message, langCode });
    throw err;
  }
}

/**
 * Fetch a single translation key for a language, falling back to English.
 */
async function getTranslation(langCode, key) {
  const translations = await getTranslations(langCode);
  
  if (translations[key] !== undefined) {
    return translations[key];
  }

  // Fallback to English
  if (langCode !== 'en') {
    const fallbackTranslations = await getTranslations('en');
    if (fallbackTranslations[key] !== undefined) {
      return fallbackTranslations[key];
    }
  }

  // Final fallback to key itself
  return key;
}

/**
 * Create or update a translation value for a language code.
 * Automatically clears cache for the modified language.
 */
async function updateTranslation(key, langCode, value) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    // 1. Ensure key exists in translation_keys
    let keyResult = await client.query('SELECT id FROM translation_keys WHERE key = $1', [key]);
    let keyId;
    if (keyResult.rows.length === 0) {
      const insertKey = await client.query(
        'INSERT INTO translation_keys (key) VALUES ($1) RETURNING id',
        [key]
      );
      keyId = insertKey.rows[0].id;
    } else {
      keyId = keyResult.rows[0].id;
    }

    // 2. Insert or update translation value
    await client.query(
      `INSERT INTO translations (key_id, language_code, value, updated_at) 
       VALUES ($1, $2, $3, NOW()) 
       ON CONFLICT (key_id, language_code) 
       DO UPDATE SET value = EXCLUDED.value, updated_at = NOW()`,
      [keyId, langCode, value]
    );

    await client.query('COMMIT');

    // 3. Clear caches
    await clearCache(langCode);

    return { success: true, key, langCode, value };
  } catch (err) {
    await client.query('ROLLBACK');
    logger.error('Failed to update translation:', { error: err.message, key, langCode });
    throw err;
  } finally {
    client.release();
  }
}

/**
 * Add a new translation key to the system.
 */
async function addTranslationKey(key, section = 'general', description = '') {
  try {
    const result = await pool.query(
      `INSERT INTO translation_keys (key, section, description) 
       VALUES ($1, $2, $3) 
       ON CONFLICT (key) DO UPDATE SET section = EXCLUDED.section, description = EXCLUDED.description
       RETURNING id`,
      [key, section, description]
    );
    return result.rows[0];
  } catch (err) {
    logger.error('Failed to add translation key:', { error: err.message, key });
    throw err;
  }
}

/**
 * Delete a translation key and all its translations.
 */
async function deleteTranslationKey(key) {
  try {
    const result = await pool.query('DELETE FROM translation_keys WHERE key = $1', [key]);
    
    // Clear all language caches since a key was deleted
    const langsResult = await pool.query('SELECT code FROM languages');
    for (const row of langsResult.rows) {
      await clearCache(row.code);
    }

    return result.rowCount > 0;
  } catch (err) {
    logger.error('Failed to delete translation key:', { error: err.message, key });
    throw err;
  }
}

/**
 * Clear Redis and local cache for a specific language
 */
async function clearCache(langCode) {
  const cacheKey = `${REDIS_PREFIX}${langCode}`;
  if (isRedisConnected()) {
    try {
      await redis.del(cacheKey);
    } catch (err) {
      logger.warn('Failed to clear Redis key:', { error: err.message, cacheKey });
    }
  }
  localCache.delete(langCode);
}

/**
 * Identify missing translations across all active languages.
 */
async function getMissingTranslationsReport() {
  try {
    const query = `
      SELECT tk.key, tk.section, l.code AS missing_language_code, l.name AS missing_language_name
      FROM translation_keys tk
      CROSS JOIN languages l
      LEFT JOIN translations t ON t.key_id = tk.id AND t.language_code = l.code
      WHERE t.id IS NULL AND l.is_active = true
      ORDER BY tk.section, tk.key;
    `;
    const result = await pool.query(query);
    return result.rows;
  } catch (err) {
    logger.error('Failed to generate missing translations report:', { error: err.message });
    throw err;
  }
}

module.exports = {
  getTranslations,
  getTranslation,
  updateTranslation,
  addTranslationKey,
  deleteTranslationKey,
  clearCache,
  getMissingTranslationsReport,
};
