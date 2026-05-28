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

  async updateShop(id, data, changedByUserId) {
    const shop = await shopRepository.update(id, data, changedByUserId);
    await cache.invalidatePattern('shops:list:*');
    return shop;
  }

  async getAuditLogs() {
    return await shopRepository.getAuditLogs();
  }

  async redeemCoins(userId, shopId) {
    const shop = await shopRepository.findById(shopId);
    if (!shop) throw new Error('Shop not found');

    const coinCost = shop.redeem_coin_cost !== null ? parseInt(shop.redeem_coin_cost) : 50;
    const userCoins = await shopRepository.getUserCoins(userId);
    if (userCoins < coinCost) {
      throw new Error(`Insufficient coins. Minimum ${coinCost} coins required for redemption.`);
    }
    return await shopRepository.redeemCoins(userId, shopId);
  }

  async getAllCoinClaims() {
    return await shopRepository.getAllCoinClaims();
  }

  async getFeaturedShop() {
    const localDate = new Date();
    const offset = localDate.getTimezoneOffset();
    const localTime = new Date(localDate.getTime() - (offset * 60 * 1000));
    const todayStr = localTime.toISOString().split('T')[0];

    let featured = await shopRepository.getFeaturedShopForDate(todayStr);
    if (featured) return featured;

    try {
      const newArrival = await shopRepository.getNewArrivalShop();
      if (newArrival) {
        await shopRepository.createFeaturedSchedule(newArrival.id, todayStr, true);
      } else {
        const activeShops = await shopRepository.getActiveShopsSorted();
        if (activeShops.length === 0) return null;

        const lastScheduled = await shopRepository.getLastScheduledEntry();
        let targetShop = activeShops[0];

        if (lastScheduled) {
          const lastIdx = activeShops.findIndex(s => s.id === lastScheduled.shop_id);
          if (lastIdx !== -1) {
            const nextIdx = (lastIdx + 1) % activeShops.length;
            targetShop = activeShops[nextIdx];
          }
        }

        await shopRepository.createFeaturedSchedule(targetShop.id, todayStr, false);
      }
      return await shopRepository.getFeaturedShopForDate(todayStr);
    } catch (err) {
      if (err.code === '23505') {
        return await shopRepository.getFeaturedShopForDate(todayStr);
      }
      throw err;
    }
  }

  async getFeaturedHistory() {
    return await shopRepository.getFeaturedHistory();
  }
}

module.exports = new ShopService();
