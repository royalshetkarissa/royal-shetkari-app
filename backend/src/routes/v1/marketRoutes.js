const express = require('express');
const router = express.Router();
const marketController = require('../../controllers/marketController');
const { verifyToken, verifyAdmin } = require('../../middleware/auth');
const upload = require('../../middleware/upload');

// Admin Routes
router.post('/shops', verifyToken, verifyAdmin, marketController.addShop);
router.post(
  '/products',
  verifyToken,
  verifyAdmin,
  upload.single('image'),
  marketController.addProduct
);

// Public/User Routes
router.get('/shops/nearby', verifyToken, marketController.getNearbyShops);

module.exports = router;
