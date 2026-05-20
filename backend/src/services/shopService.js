const shopRepository = require('../repositories/shopRepository');
const cache = require('../utils/cache');

class ShopService {
  async addShop(data) {
    const shop = await shopRepository.create(data);
    await cache.invalidatePattern('shops:list:*');
    return shop;
  }

  async getNearbyShops(lat, lng) {
    const cacheKey = `shops:list:${lat}:${lng}`;
    const cached = await cache.get(cacheKey);
    if (cached) return cached;

    const shops = await shopRepository.findAll({ userLat: lat, userLng: lng, status: 'active' });
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

  async deleteShop(id) {
    await shopRepository.delete(id);
    await cache.invalidatePattern('shops:list:*');
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
}

module.exports = new ShopService();
