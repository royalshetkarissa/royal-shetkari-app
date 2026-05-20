const shopService = require('../services/shopService');
const { logActivity } = require('../utils/logger');

exports.addShop = async (req, res, next) => {
  try {
    const { name, address, contact_mobile, whatsapp_number, categories, latitude, longitude, owner_name, services, pincode, city } = req.body;
    
    let profilePhoto = null;
    let images = [];

    if (req.files) {
      if (req.files['profile_photo']) {
        profilePhoto = `/uploads/${req.files['profile_photo'][0].filename}`;
      }
      if (req.files['images']) {
        images = req.files['images'].map(f => `/uploads/${f.filename}`);
      }
    }

    const shop = await shopService.addShop({
      name,
      address,
      contact_mobile,
      whatsapp_number,
      categories: typeof categories === 'string' ? JSON.parse(categories) : categories,
      images,
      profile_photo: profilePhoto,
      latitude: parseFloat(latitude),
      longitude: parseFloat(longitude),
      ownerId: req.userId,
      owner_name,
      services,
      pincode,
      city
    });

    await logActivity(req.userId, 'ADD_SHOP', 'shop', shop.id, { name });
    res.status(201).json({ success: true, shop });
  } catch (err) {
    next(err);
  }
};

exports.getNearbyShops = async (req, res, next) => {
  try {
    const { lat, lng } = req.query;
    const shops = await shopService.getNearbyShops(parseFloat(lat), parseFloat(lng));
    res.json({ success: true, shops });
  } catch (err) {
    next(err);
  }
};

exports.getAdminShops = async (req, res, next) => {
  try {
    const shops = await shopService.getAdminShops();
    res.json({ success: true, shops });
  } catch (err) {
    next(err);
  }
};

exports.activateShop = async (req, res, next) => {
  try {
    const shop = await shopService.activateShop(req.params.id);
    res.json({ success: true, shop });
  } catch (err) {
    next(err);
  }
};

exports.deleteShop = async (req, res, next) => {
  try {
    await shopService.deleteShop(req.params.id);
    res.json({ success: true, message: 'Shop deleted' });
  } catch (err) {
    next(err);
  }
};

exports.trackClick = async (req, res, next) => {
  try {
    const { type } = req.body; // 'call', 'whatsapp', 'view'
    await shopService.trackClick(req.params.id, req.userId, type);
    res.json({ success: true });
  } catch (err) {
    next(err);
  }
};

exports.getAnalytics = async (req, res, next) => {
  try {
    const stats = await shopService.getAnalytics();
    res.json({ success: true, stats });
  } catch (err) {
    next(err);
  }
};

exports.getShopClicks = async (req, res, next) => {
  try {
    const clicks = await shopService.getShopClicks(req.params.shopId);
    res.json({ success: true, clicks });
  } catch (err) {
    next(err);
  }
};
