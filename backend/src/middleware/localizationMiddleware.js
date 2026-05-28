const SUPPORTED_LANGUAGES = ['en', 'hi', 'mr', 'ta', 'gu'];
const FALLBACK_LANGUAGE = 'en';

/**
 * Middleware to detect and set the request language.
 * Checks:
 * 1. Query parameter: ?lang=mr
 * 2. Header: Accept-Language: mr, en-US;q=0.9
 */
module.exports = (req, res, next) => {
  let detectedLang = null;

  // 1. Check query parameter 'lang'
  if (req.query && req.query.lang) {
    const queryLang = req.query.lang.toString().toLowerCase().trim();
    if (SUPPORTED_LANGUAGES.includes(queryLang)) {
      detectedLang = queryLang;
    }
  }

  // 2. Check request body 'lang'
  if (!detectedLang && req.body && req.body.lang) {
    const bodyLang = req.body.lang.toString().toLowerCase().trim();
    if (SUPPORTED_LANGUAGES.includes(bodyLang)) {
      detectedLang = bodyLang;
    }
  }

  // 3. Check Accept-Language header
  if (!detectedLang && req.headers && req.headers['accept-language']) {
    const acceptHeader = req.headers['accept-language'];
    // Format is typically: en-US,en;q=0.9,mr;q=0.8
    const languages = acceptHeader.split(',').map((lang) => {
      const parts = lang.split(';');
      const code = parts[0].trim().split('-')[0].toLowerCase(); // Get main code (e.g. 'mr' from 'mr-IN')
      return code;
    });

    for (const code of languages) {
      if (SUPPORTED_LANGUAGES.includes(code)) {
        detectedLang = code;
        break;
      }
    }
  }

  // 4. Check user profile preference if authenticated
  if (!detectedLang && req.user && req.user.language_preference) {
    const userLang = req.user.language_preference.toLowerCase().trim();
    if (SUPPORTED_LANGUAGES.includes(userLang)) {
      detectedLang = userLang;
    }
  }

  // Fallback to English
  req.language = detectedLang || FALLBACK_LANGUAGE;

  // Set response header for tracking/debugging
  res.setHeader('Content-Language', req.language);

  next();
};
