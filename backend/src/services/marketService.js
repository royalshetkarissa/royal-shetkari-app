const marketRepository = require('../repositories/marketRepository');

class MarketService {
  async addShop(data) {
    return await marketRepository.createShop(data);
  }

  async addProduct(data) {
    return await marketRepository.createShopProduct(data);
  }

  async getNearbyShops(lat, lng, radiusKm) {
    return await marketRepository.getNearbyShops(lat, lng, radiusKm);
  }
}

module.exports = new MarketService();
