const express = require('express');
const router = express.Router();
const diseaseController = require('../../controllers/diseaseController');
const { verifyToken } = require('../../middleware/auth');
const upload = require('../../middleware/upload');

router.post('/scan', verifyToken, upload.single('image'), diseaseController.scanDisease);
router.get('/history', verifyToken, diseaseController.getHistory);
router.delete('/history/:id', verifyToken, diseaseController.deleteHistory);

module.exports = router;
