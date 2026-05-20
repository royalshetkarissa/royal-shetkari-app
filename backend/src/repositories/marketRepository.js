const pool = require('../config/db');

class MarketRepository {
  async createShop(data) {
    const { name, locationName, latitude, longitude } = data;
    const result = await pool.queryWithRetry(
      `INSERT INTO shops (name, location_name, latitude, longitude) VALUES ($1, $2, $3, $4) RETURNING *`,
      [name, locationName, latitude, longitude]
    );
    return result.rows[0];
  }

  async createShopProduct(data) {
    const { shopId, name, imageUrl, price, isOrganic } = data;
    const result = await pool.queryWithRetry(
      `INSERT INTO shop_products (shop_id, name, image_url, price, is_organic) VALUES ($1, $2, $3, $4, $5) RETURNING *`,
      [shopId, name, imageUrl, price, isOrganic]
    );
    return result.rows[0];
  }

  async getNearbyShops(userLat, userLng, radiusKm = 50) {
    let query = `
      SELECT s.*, 
      (6371 * acos(cos(radians($1)) * cos(radians(s.latitude)) * cos(radians(s.longitude) - radians($2)) + sin(radians($1)) * sin(radians(s.latitude)))) AS distance
      FROM shops s
      WHERE (6371 * acos(cos(radians($1)) * cos(radians(s.latitude)) * cos(radians(s.longitude) - radians($2)) + sin(radians($1)) * sin(radians(s.latitude)))) <= $3
      ORDER BY distance ASC
    `;
    const shops = await pool.queryWithRetry(query, [userLat, userLng, radiusKm]);

    // Fetch products for these shops
    const shopIds = shops.rows.map(s => s.id);
    if (shopIds.length === 0) return [];

    const productsResult = await pool.queryWithRetry(
      `SELECT * FROM shop_products WHERE shop_id = ANY($1)`,
      [shopIds]
    );

    const productsByShopId = {};
    productsResult.rows.forEach(p => {
      if (!productsByShopId[p.shop_id]) {
        productsByShopId[p.shop_id] = [];
      }
      productsByShopId[p.shop_id].push(p);
    });

    return shops.rows.map(shop => ({
      ...shop,
      products: productsByShopId[shop.id] || []
    }));
  }
}

module.exports = new MarketRepository();
