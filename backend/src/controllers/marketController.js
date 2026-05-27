const marketService = require('../services/marketService');
const AppError = require('../utils/AppError');

exports.addShop = async (req, res, next) => {
  try {
    const shop = await marketService.addShop(req.body);
    res.status(201).json({ success: true, shop });
  } catch (error) {
    next(error);
  }
};

exports.addProduct = async (req, res, next) => {
  try {
    let imageUrl = null;
    if (req.file) {
      imageUrl = `/uploads/${req.file.filename}`;
    }

    const productData = {
      ...req.body,
      imageUrl,
      isOrganic: req.body.isOrganic === 'true' || req.body.isOrganic === true,
    };

    const product = await marketService.addProduct(productData);
    res.status(201).json({ success: true, product });
  } catch (error) {
    next(error);
  }
};

exports.getNearbyShops = async (req, res, next) => {
  try {
    const { lat, lng, radius } = req.query;
    if (!lat || !lng) {
      return next(new AppError('Latitude and longitude are required to find nearby shops', 400));
    }
    const shops = await marketService.getNearbyShops(
      parseFloat(lat),
      parseFloat(lng),
      radius ? parseFloat(radius) : 50
    );
    res.json({ success: true, shops });
  } catch (error) {
    next(error);
  }
};
