const express = require('express');
const router = express.Router();
const shopController = require('../../controllers/shopController');
const { verifyToken, verifyAdmin: isAdmin } = require('../../middleware/auth');
const b2Upload = require('../../middleware/b2Upload');

// Public/Farmer Market Routes
router.get('/nearby', shopController.getNearbyShops);
router.get('/featured', shopController.getFeaturedShop);
router.post('/:id/click', verifyToken, shopController.trackClick);
router.post('/:id/redeem', verifyToken, shopController.redeemShopCoins);

// Admin Routes
router.get('/admin/featured-history', verifyToken, isAdmin, shopController.getFeaturedHistory);
router.post(
  '/admin/add',
  verifyToken,
  isAdmin,
  b2Upload.fields([
    { name: 'profile_photo', maxCount: 1 },
    { name: 'images', maxCount: 10 },
  ]),
  shopController.addShop
);

router.get('/admin/list', verifyToken, isAdmin, shopController.getAdminShops);
router.post('/admin/:id/activate', verifyToken, isAdmin, shopController.activateShop);
router.delete('/admin/:id', verifyToken, isAdmin, shopController.deleteShop);
router.get('/admin/analytics', verifyToken, isAdmin, shopController.getAnalytics);
router.get('/admin/shop-clicks/:shopId', verifyToken, isAdmin, shopController.getShopClicks);
router.get('/admin/coin-claims', verifyToken, isAdmin, shopController.getAdminCoinClaims);
router.get('/admin/audit-logs', verifyToken, isAdmin, shopController.getAuditLogs);
router.put(
  '/admin/edit/:id',
  verifyToken,
  isAdmin,
  b2Upload.fields([
    { name: 'profile_photo', maxCount: 1 },
    { name: 'images', maxCount: 10 },
  ]),
  shopController.editShop
);

module.exports = router;
