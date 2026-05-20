const express = require('express');
const router = express.Router();
const hospitalController = require('../../controllers/hospitalController');
const { verifyToken, verifyAdmin } = require('../../middleware/auth');

// Apply token validation globally for all hospital operations
router.use(verifyToken);

// User-Facing Routes
router.get('/', hospitalController.getActiveHospitals);
router.post('/:id/redeem', hospitalController.redeemCoins);
router.get('/history', hospitalController.getRedemptionHistory);

// Admin-Facing Routes
router.post('/', verifyAdmin, hospitalController.addHospital);
router.delete('/:id', verifyAdmin, hospitalController.deleteHospital);
router.get('/redemptions', verifyAdmin, hospitalController.getAllRedemptions);

module.exports = router;
