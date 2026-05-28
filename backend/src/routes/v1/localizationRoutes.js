const express = require('express');
const router = express.Router();
const localizationController = require('../../controllers/localizationController');
const { verifyToken, verifyAdmin } = require('../../middleware/auth');

// Public endpoints
router.get('/languages', localizationController.getLanguages);
router.get('/translations', localizationController.getTranslations);
router.get('/translate/:key', localizationController.translateKey);

// Authenticated user endpoints
router.put('/preference', verifyToken, localizationController.updateUserPreference);

// Admin-only management endpoints
router.post('/translations', verifyAdmin, localizationController.updateTranslation);
router.post('/keys', verifyAdmin, localizationController.addTranslationKey);
router.delete('/keys/:key', verifyAdmin, localizationController.deleteTranslationKey);
router.get('/report/missing', verifyAdmin, localizationController.getMissingTranslationsReport);

module.exports = router;
