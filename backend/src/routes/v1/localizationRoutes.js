const express = require('express');
const router = express.Router();
const localizationController = require('../../controllers/localizationController');
const { verifyToken, isAdmin } = require('../../middleware/auth');

// Public endpoints
router.get('/languages', localizationController.getLanguages);
router.get('/translations', localizationController.getTranslations);

// Admin-only management endpoints
router.post('/translations', verifyToken, isAdmin, localizationController.updateTranslation);
router.post('/keys', verifyToken, isAdmin, localizationController.addTranslationKey);
router.delete('/keys/:key', verifyToken, isAdmin, localizationController.deleteTranslationKey);
router.get('/report/missing', verifyToken, isAdmin, localizationController.getMissingTranslationsReport);

module.exports = router;
