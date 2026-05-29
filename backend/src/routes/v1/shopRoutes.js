const express = require('express');
const router = express.Router();
const shopController = require('../../controllers/shopController');
const { verifyToken, verifyAdmin: isAdmin } = require('../../middleware/auth');
const upload = require('../../middleware/upload');

// Public/Farmer Market Routes
router.get('/nearby', shopController.getNearbyShops);
router.post('/:id/click', verifyToken, shopController.trackClick);
router.post('/:id/redeem', verifyToken, shopController.redeemShopCoins);

// Admin Routes
router.post(
  '/admin/add',
  verifyToken,
  isAdmin,
  upload.fields([
    { name: 'profile_photo', maxCount: 1 },
    { name: 'images', maxCount: 10 },
  ]),
  shopController.addShop
);

router.get('/admin/list', verifyToken, isAdmin, shopController.getAdminShops);
router.put(
  '/admin/:id/update',
  verifyToken,
  isAdmin,
  upload.fields([
    { name: 'profile_photo', maxCount: 1 },
    { name: 'images', maxCount: 10 },
  ]),
  shopController.updateShop
);
router.post('/admin/:id/activate', verifyToken, isAdmin, shopController.activateShop);
router.delete('/admin/:id', verifyToken, isAdmin, shopController.deleteShop);
router.get('/admin/analytics', verifyToken, isAdmin, shopController.getAnalytics);
router.get('/admin/shop-clicks/:shopId', verifyToken, isAdmin, shopController.getShopClicks);
router.get('/admin/coin-claims', verifyToken, isAdmin, shopController.getAdminCoinClaims);
router.get('/admin/claims-stream', verifyToken, isAdmin, shopController.claimsStream);

module.exports = router;
