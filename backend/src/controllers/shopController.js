const shopService = require('../services/shopService');
const { logActivity } = require('../utils/logger');
const { uploadToB2 } = require('../utils/b2Uploader');

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
      redeem_coin_cost,
      discount_percentage,
    } = req.body;

    let profilePhoto = null;
    let images = [];

    if (req.files) {
      if (req.files['profile_photo'] && req.files['profile_photo'][0]) {
        profilePhoto = await uploadToB2(req.files['profile_photo'][0]);
      }
      if (req.files['images'] && req.files['images'].length > 0) {
        images = await Promise.all(
          req.files['images'].map((f) => uploadToB2(f))
        );
        images = images.filter(Boolean);
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
      redeem_coin_cost,
      discount_percentage,
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

exports.editShop = async (req, res, next) => {
  try {
    const shopId = parseInt(req.params.id);
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
      redeem_coin_cost,
      discount_percentage,
      status,
    } = req.body;

    let profilePhoto = null;
    let images = [];

    if (req.files) {
      if (req.files['profile_photo'] && req.files['profile_photo'][0]) {
        profilePhoto = await uploadToB2(req.files['profile_photo'][0]);
      }
      if (req.files['images'] && req.files['images'].length > 0) {
        images = await Promise.all(
          req.files['images'].map((f) => uploadToB2(f))
        );
        images = images.filter(Boolean);
      }
    }

    const updatedData = {
      name,
      address,
      contact_mobile,
      whatsapp_number,
      latitude:
        latitude !== undefined && !isNaN(parseFloat(latitude)) ? parseFloat(latitude) : undefined,
      longitude:
        longitude !== undefined && !isNaN(parseFloat(longitude))
          ? parseFloat(longitude)
          : undefined,
      owner_name,
      services,
      pincode,
      city,
      redeem_coin_cost:
        redeem_coin_cost !== undefined && !isNaN(parseInt(redeem_coin_cost))
          ? parseInt(redeem_coin_cost)
          : undefined,
      discount_percentage:
        discount_percentage !== undefined && !isNaN(parseFloat(discount_percentage))
          ? parseFloat(discount_percentage)
          : undefined,
      status,
    };

    if (categories !== undefined) {
      updatedData.categories = (() => {
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
      })();
    }

    if (profilePhoto) {
      updatedData.profile_photo = profilePhoto;
    }
    if (images.length > 0) {
      updatedData.images = images;
    }

    const shop = await shopService.updateShop(shopId, updatedData, req.userId);
    await logActivity(req.userId, 'EDIT_SHOP', 'shop', shopId, { name: shop.name });
    res.json({ success: true, shop });
  } catch (err) {
    next(err);
  }
};

exports.getAuditLogs = async (req, res, next) => {
  try {
    const logs = await shopService.getAuditLogs();
    res.json({ success: true, logs });
  } catch (err) {
    next(err);
  }
};

exports.getFeaturedShop = async (req, res, next) => {
  try {
    const shop = await shopService.getFeaturedShop();
    res.json({ success: true, shop });
  } catch (err) {
    next(err);
  }
};

exports.getFeaturedHistory = async (req, res, next) => {
  try {
    const history = await shopService.getFeaturedHistory();
    res.json({ success: true, history });
  } catch (err) {
    next(err);
  }
};

