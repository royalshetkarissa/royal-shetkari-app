const shopRepository = require('../repositories/shopRepository');
const cache = require('../utils/cache');

class ShopService {
  async addShop(data) {
    const shop = await shopRepository.create(data);
    await cache.invalidatePattern('shops:list:*');
    return shop;
  }

  async getNearbyShops(params) {
    const { lat, lng, radius_km, sortBy } = params;
    const cacheKey = `shops:list:${lat}:${lng}:${radius_km}:${sortBy}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const shops = await shopRepository.findAll({
      userLat: lat,
      userLng: lng,
      radius_km,
      sortBy,
      status: 'active'
    });
    await cache.set(cacheKey, shops, 600); // 10 min cache
    return shops;
  }

  async getAdminShops() {
    return await shopRepository.findAdminShops();
  }

  async activateShop(id) {
    const shop = await shopRepository.updateStatus(id, 'active');
    await cache.invalidatePattern('shops:list:*');
    return shop;
  }

  async deactivateShop(id) {
    const shop = await shopRepository.updateStatus(id, 'inactive');
    await cache.invalidatePattern('shops:list:*');
    return shop;
  }

  async deleteShop(id) {
    await shopRepository.delete(id);
    await cache.invalidatePattern('shops:list:*');
  }

  async updateShop(id, data) {
    const shop = await shopRepository.update(id, data);
    await cache.invalidatePattern('shops:list:*');
    return shop;
  }

  async trackClick(shopId, userId, type) {
    await shopRepository.logClick(shopId, userId, type);
  }

  async getAnalytics() {
    return await shopRepository.getStats();
  }

  async getShopClicks(shopId) {
    return await shopRepository.getShopClicks(shopId);
  }

  async redeemCoins(userId, shopId) {
    const shop = await shopRepository.findById(shopId);
    if (!shop) {
      throw new Error('Shop not found.');
    }
    const coinsRequired = shop.coins_required || 50;
    const userCoins = await shopRepository.getUserCoins(userId);
    if (userCoins < coinsRequired) {
      throw new Error(`Insufficient coins. Minimum ${coinsRequired} coins required for redemption.`);
    }
    return await shopRepository.redeemCoins(userId, shopId);
  }

  async getAllCoinClaims() {
    return await shopRepository.getAllCoinClaims();
  }

  async getShopById(id) {
    return await shopRepository.findById(id);
  }
}

module.exports = new ShopService();
