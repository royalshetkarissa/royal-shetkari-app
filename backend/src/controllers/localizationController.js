const translationService = require('../services/translationService');
const pool = require('../config/db');
const AppError = require('../utils/AppError');

/**
 * Get active languages supported by the system
 */
exports.getLanguages = async (req, res, next) => {
  try {
    const result = await pool.query(
      'SELECT code, name, is_active FROM languages WHERE is_active = true'
    );
    res.json({
      success: true,
      languages: result.rows,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Get translations map for the requested language
 */
exports.getTranslations = async (req, res, next) => {
  try {
    const lang = req.query.lang || req.language || 'en';
    const translations = await translationService.getTranslations(lang);
    res.json({
      success: true,
      language: lang,
      translations,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Add or update translation value
 */
exports.updateTranslation = async (req, res, next) => {
  try {
    const { key, lang, value } = req.body;

    if (!key || !lang || value === undefined) {
      return next(new AppError('Please provide key, lang, and value fields', 400));
    }

    const result = await translationService.updateTranslation(key, lang, value);
    res.json({
      success: true,
      message: 'Translation updated successfully',
      data: result,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Register a new translation key
 */
exports.addTranslationKey = async (req, res, next) => {
  try {
    const { key, section, description } = req.body;

    if (!key) {
      return next(new AppError('Please provide a translation key', 400));
    }

    const result = await translationService.addTranslationKey(
      key,
      section || 'general',
      description || ''
    );
    res.status(201).json({
      success: true,
      message: 'Translation key registered successfully',
      data: result,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Delete a translation key
 */
exports.deleteTranslationKey = async (req, res, next) => {
  try {
    const { key } = req.params;

    if (!key) {
      return next(new AppError('Please provide key parameter', 400));
    }

    const deleted = await translationService.deleteTranslationKey(key);
    if (!deleted) {
      return next(new AppError('Translation key not found', 404));
    }

    res.json({
      success: true,
      message: `Translation key '${key}' deleted successfully`,
    });
  } catch (err) {
    next(err);
  }
};

/**
 * Fetch report of missing translation entries
 */
exports.getMissingTranslationsReport = async (req, res, next) => {
  try {
    const report = await translationService.getMissingTranslationsReport();
    res.json({
      success: true,
      count: report.length,
      report,
    });
  } catch (err) {
    next(err);
  }
};
