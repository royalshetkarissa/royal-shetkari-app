const express = require('express');
const router = express.Router();
const analyticsController = require('../../controllers/analyticsController');
const { verifyToken } = require('../../middleware/auth');

router.post('/impressions', verifyToken, analyticsController.logImpression);

module.exports = router;
