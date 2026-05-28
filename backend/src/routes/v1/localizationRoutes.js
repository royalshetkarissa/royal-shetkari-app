const express = require('express');
const router = express.Router();
const localizationController = require('../../controllers/localizationController');
const { verifyToken, verifyAdmin } = require('../../middleware/auth');

// Public endpoints
router.get('/languages', localizationController.getLanguages);
router.get('/translations', localizationController.getTranslations);

// Admin-only management endpoints
router.post('/translations', verifyAdmin, localizationController.updateTranslation);
router.post('/keys', verifyAdmin, localizationController.addTranslationKey);
router.delete('/keys/:key', verifyAdmin, localizationController.deleteTranslationKey);
router.get('/report/missing', verifyAdmin, localizationController.getMissingTranslationsReport);

module.exports = router;
