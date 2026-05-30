const shopService = require('../services/shopService');
const { logActivity } = require('../utils/logger');

const safeParseJson = (value) => {
  if (typeof value === 'string') {
    try {
      return JSON.parse(value);
    } catch (e) {
      if (value.includes(',')) {
        return value.split(',').map((s) => s.trim()).filter(Boolean);
      }
      return [value.trim()];
    }
  }
  return value;
};

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
      coins_required,
      discount_percentage,
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
      categories: safeParseJson(categories),
      images,
      profile_photo: profilePhoto,
      latitude: latitude && !isNaN(parseFloat(latitude)) ? parseFloat(latitude) : 19.076,
      longitude: longitude && !isNaN(parseFloat(longitude)) ? parseFloat(longitude) : 72.8777,
      ownerId: req.userId,
      owner_name,
      services,
      pincode,
      city,
      coins_required: coins_required && !isNaN(parseInt(coins_required)) ? parseInt(coins_required) : 50,
      discount_percentage: discount_percentage && !isNaN(parseFloat(discount_percentage)) ? parseFloat(discount_percentage) : 5.0,
    });

    await logActivity(req.userId, 'ADD_SHOP', 'shop', shop.id, { name });
    res.status(201).json({ success: true, shop });
  } catch (err) {
    next(err);
  }
};

exports.getNearbyShops = async (req, res, next) => {
  try {
    const lat = req.query.lat || req.query.latitude;
    const lng = req.query.lng || req.query.longitude;
    const radius_km = req.query.radius_km;
    const sortBy = req.query.sortBy;

    const shops = await shopService.getNearbyShops({
      lat: lat ? parseFloat(lat) : null,
      lng: lng ? parseFloat(lng) : null,
      radius_km: radius_km ? parseFloat(radius_km) : null,
      sortBy
    });
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

exports.deactivateShop = async (req, res, next) => {
  try {
    const shop = await shopService.deactivateShop(req.params.id);
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

let sseClients = [];

exports.claimsStream = (req, res) => {
  res.setHeader('Content-Type', 'text/event-stream');
  res.setHeader('Cache-Control', 'no-cache');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders();

  sseClients.push(res);

  req.on('close', () => {
    sseClients = sseClients.filter(c => c !== res);
  });
};

exports.redeemShopCoins = async (req, res, next) => {
  try {
    const shopId = parseInt(req.params.id);
    const { newCoins, claim } = await shopService.redeemCoins(req.userId, shopId);

    await logActivity(req.userId, 'REDEEM_COINS_SHOP', 'shop', shopId, {
      claimCode: claim.claim_code,
    });

    // Broadcast new claim event in real-time
    const broadcastData = {
      id: claim.id,
      shop_id: claim.shop_id,
      user_id: claim.user_id,
      coins_redeemed: claim.coins_redeemed,
      discount_percentage: claim.discount_percentage,
      claim_code: claim.claim_code,
      created_at: claim.created_at,
    };
    sseClients.forEach(client => {
      client.write(`data: ${JSON.stringify(broadcastData)}\n\n`);
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

exports.updateShop = async (req, res, next) => {
  try {
    const shopId = parseInt(req.params.id);
    const existingShop = await shopService.getShopById(shopId);
    if (!existingShop) {
      return res.status(404).json({ success: false, message: 'Shop not found' });
    }

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
      coins_required,
      discount_percentage,
      status,
    } = req.body;

    let profilePhoto = existingShop.profile_photo;
    if (req.files && req.files['profile_photo']) {
      profilePhoto = `/uploads/${req.files['profile_photo'][0].filename}`;
    } else if (req.body.profile_photo === '') {
      profilePhoto = null;
    }

    let images = existingShop.images || [];
    if (req.body.existing_images !== undefined) {
      images = safeParseJson(req.body.existing_images);
    }
    if (req.files && req.files['images']) {
      const newImages = req.files['images'].map((f) => `/uploads/${f.filename}`);
      images = [...images, ...newImages];
    }

    const updateData = {};
    if (name !== undefined) updateData.name = name;
    if (address !== undefined) updateData.address = address;
    if (contact_mobile !== undefined) updateData.contact_mobile = contact_mobile;
    if (whatsapp_number !== undefined) updateData.whatsapp_number = whatsapp_number;
    if (categories !== undefined) {
      updateData.categories = safeParseJson(categories);
    }
    if (latitude !== undefined && latitude !== '' && !isNaN(parseFloat(latitude))) {
      updateData.latitude = parseFloat(latitude);
    }
    if (longitude !== undefined && longitude !== '' && !isNaN(parseFloat(longitude))) {
      updateData.longitude = parseFloat(longitude);
    }
    if (owner_name !== undefined) updateData.owner_name = owner_name;
    if (services !== undefined) updateData.services = services;
    if (pincode !== undefined) updateData.pincode = pincode;
    if (city !== undefined) updateData.city = city;
    if (coins_required !== undefined && coins_required !== '' && !isNaN(parseInt(coins_required))) {
      updateData.coins_required = parseInt(coins_required);
    }
    if (discount_percentage !== undefined && discount_percentage !== '' && !isNaN(parseFloat(discount_percentage))) {
      updateData.discount_percentage = parseFloat(discount_percentage);
    }
    if (status !== undefined) updateData.status = status;

    updateData.profile_photo = profilePhoto;
    updateData.images = images;

    const shop = await shopService.updateShop(shopId, updateData);
    await logActivity(req.userId, 'UPDATE_SHOP', 'shop', shopId, updateData);

    res.json({ success: true, shop });
  } catch (err) {
    next(err);
  }
};

exports.diagnoseShopsTable = async (req, res, next) => {
  try {
    const pool = require('../config/db');
    const migrationRunner = require('../utils/migrationRunner');
    
    let migrationError = null;
    let migrationStatus = 'no_action_taken';
    try {
      await migrationRunner.up();
      migrationStatus = 'migrations_run_successfully';
    } catch (err) {
      migrationError = { message: err.message, stack: err.stack };
      migrationStatus = 'migrations_failed';
    }
    
    const columnsRes = await pool.query(`
      SELECT column_name, data_type, is_nullable, column_default
      FROM information_schema.columns 
      WHERE table_name = 'shops'
      ORDER BY column_name
    `);
    
    let appliedMigrations = [];
    try {
      const migrationsRes = await pool.query(`
        SELECT * FROM migrations_meta ORDER BY applied_at DESC LIMIT 15
      `);
      appliedMigrations = migrationsRes.rows;
    } catch (e) {
      appliedMigrations = [{ error: e.message }];
    }
    
    res.json({
      success: true,
      migrationStatus,
      migrationError,
      columns: columnsRes.rows,
      appliedMigrations
    });
  } catch (err) {
    res.status(500).json({
      success: false,
      error: err.message,
      stack: err.stack
    });
  }
};
