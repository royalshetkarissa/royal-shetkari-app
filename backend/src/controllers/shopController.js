const shopService = require('../services/shopService');
const { logActivity } = require('../utils/logger');

exports.addShop = async (req, res, next) => {
  try {
    const {
      name,
      address,
      contact_mobile,
      whatsapp_number,
      categories,
      latitude,
      longitude,
      owner_name,
      services,
      pincode,
      city,
    } = req.body;

    let profilePhoto = null;
    let images = [];

    if (req.files) {
      if (req.files['profile_photo']) {
        profilePhoto = `/uploads/${req.files['profile_photo'][0].filename}`;
      }
      if (req.files['images']) {
        images = req.files['images'].map((f) => `/uploads/${f.filename}`);
      }
    }

    const shop = await shopService.addShop({
      name,
      address,
      contact_mobile,
      whatsapp_number,
      categories: (() => {
        if (!categories) return [];
        if (typeof categories === 'string') {
          const trimmed = categories.trim();
          if (trimmed.startsWith('[') || trimmed.startsWith('{')) {
            try {
              return JSON.parse(trimmed);
            } catch (e) {
              return trimmed
                .split(',')
                .map((s) => s.trim())
                .filter(Boolean);
            }
          }
          return trimmed
            .split(',')
            .map((s) => s.trim())
            .filter(Boolean);
        }
        return Array.isArray(categories) ? categories : [categories];
      })(),
      images,
      profile_photo: profilePhoto,
      latitude: latitude && !isNaN(parseFloat(latitude)) ? parseFloat(latitude) : 19.076,
      longitude: longitude && !isNaN(parseFloat(longitude)) ? parseFloat(longitude) : 72.8777,
      ownerId: req.userId,
      owner_name,
      services,
      pincode,
      city,
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

exports.redeemShopCoins = async (req, res, next) => {
  try {
    const shopId = parseInt(req.params.id);
    const { newCoins, claim } = await shopService.redeemCoins(req.userId, shopId);

    await logActivity(req.userId, 'REDEEM_COINS_SHOP', 'shop', shopId, {
      claimCode: claim.claim_code,
    });
    res.json({ success: true, newCoins, claim });
  } catch (err) {
    next(err);
  }
};

exports.getAdminCoinClaims = async (req, res, next) => {
  try {
    const claims = await shopService.getAllCoinClaims();
    res.json({ success: true, claims });
  } catch (err) {
    next(err);
  }
};
