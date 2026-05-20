const express = require('express');
const router = express.Router();
const shopController = require('../../controllers/shopController');
const { verifyToken, verifyAdmin: isAdmin } = require('../../middleware/auth');
const upload = require('../../middleware/upload');

// Public/Farmer Market Routes
router.get('/nearby', shopController.getNearbyShops);
router.post('/:id/click', verifyToken, shopController.trackClick);

// Admin Routes
router.post('/admin/add', verifyToken, isAdmin, upload.fields([
  { name: 'profile_photo', maxCount: 1 },
  { name: 'images', maxCount: 10 }
]), shopController.addShop);

router.get('/admin/list', verifyToken, isAdmin, shopController.getAdminShops);
router.post('/admin/:id/activate', verifyToken, isAdmin, shopController.activateShop);
router.delete('/admin/:id', verifyToken, isAdmin, shopController.deleteShop);
router.get('/admin/analytics', verifyToken, isAdmin, shopController.getAnalytics);
router.get('/admin/shop-clicks/:shopId', verifyToken, isAdmin, shopController.getShopClicks);

module.exports = router;
