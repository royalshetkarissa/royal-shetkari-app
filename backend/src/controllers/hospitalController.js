const hospitalService = require('../services/hospitalService');
const logger = require('../utils/logger');

exports.addHospital = async (req, res, next) => {
  try {
    const { name, location, contactNumber, service } = req.body;
    if (!name || !location || !contactNumber || !service) {
      return res.status(400).json({ success: false, message: 'All hospital details are required.' });
    }

    const hospital = await hospitalService.addHospital({ name, location, contactNumber, service });
    
    // Log Admin Action
    await logger.logActivity(req.userId, 'ADD_HOSPITAL', 'hospital', hospital.id, { name, location });

    res.status(201).json({ success: true, hospital });
  } catch (err) {
    next(err);
  }
};

exports.getActiveHospitals = async (req, res, next) => {
  try {
    const hospitals = await hospitalService.getActiveHospitals();
    res.json({ success: true, hospitals });
  } catch (err) {
    next(err);
  }
};

exports.deleteHospital = async (req, res, next) => {
  try {
    const hospital = await hospitalService.deleteHospital(req.params.id);
    if (!hospital) {
      return res.status(404).json({ success: false, message: 'Hospital not found.' });
    }

    // Log Admin Action
    await logger.logActivity(req.userId, 'DELETE_HOSPITAL', 'hospital', parseInt(req.params.id), { name: hospital.name });

    res.json({ success: true, message: 'Hospital successfully deleted.' });
  } catch (err) {
    next(err);
  }
};

exports.redeemCoins = async (req, res, next) => {
  try {
    const { newCoins, redemption } = await hospitalService.redeemCoins(req.userId, parseInt(req.params.id));
    
    // Log User Action
    await logger.logActivity(req.userId, 'REDEEM_COINS_HOSPITAL', 'hospital', parseInt(req.params.id), { coins_redeemed: 50 });

    res.json({ success: true, newCoins, redemption });
  } catch (err) {
    res.status(400).json({ success: false, message: err.message });
  }
};

exports.getAllRedemptions = async (req, res, next) => {
  try {
    const redemptions = await hospitalService.getAllRedemptions();
    res.json({ success: true, redemptions });
  } catch (err) {
    next(err);
  }
};

exports.getRedemptionHistory = async (req, res, next) => {
  try {
    const history = await hospitalService.getRedemptionHistory(req.userId);
    res.json({ success: true, history });
  } catch (err) {
    next(err);
  }
};
