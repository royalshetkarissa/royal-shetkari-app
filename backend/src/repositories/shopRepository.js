const pool = require('../config/db');

class ShopRepository {
  async create(data) {
    const {
      name,
      profile_photo,
      address,
      contact_mobile,
      whatsapp_number,
      categories,
      images,
      latitude,
      longitude,
      ownerId,
      owner_name,
      services,
      pincode,
      city,
    } = data;
    const result = await pool.query(
      `INSERT INTO shops (name, profile_photo, address, contact_mobile, whatsapp_number, categories, images, latitude, longitude, owner_id, owner_name, services, pincode, city) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14) RETURNING *`,
      [
        name,
        profile_photo,
        address,
        contact_mobile,
        whatsapp_number,
        JSON.stringify(categories),
        JSON.stringify(images),
        latitude,
        longitude,
        ownerId,
        owner_name,
        services,
        pincode,
        city,
      ]
    );
    return result.rows[0];
  }

  async findAll(filters) {
    const { userLat, userLng, status = 'active' } = filters;

    const query = `
      SELECT *, 
      (6371 * acos(cos(radians($1)) * cos(radians(latitude)) * cos(radians(longitude) - radians($2)) + sin(radians($1)) * sin(radians(latitude)))) AS distance
      FROM shops
      WHERE status = $3
      ORDER BY distance ASC
    `;

    const result = await pool.query(query, [userLat || 0, userLng || 0, status]);
    return result.rows;
  }

  async findAdminShops() {
    const result = await pool.query(
      `SELECT * FROM shops WHERE status != 'deleted' ORDER BY created_at DESC`
    );
    return result.rows;
  }

  async updateStatus(id, status) {
    const result = await pool.query(
      `UPDATE shops SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [status, id]
    );
    return result.rows[0];
  }

  async delete(id) {
    await pool.query(`UPDATE shops SET status = 'deleted' WHERE id = $1`, [id]);
  }

  async findById(id) {
    const result = await pool.query(`SELECT * FROM shops WHERE id = $1`, [id]);
    return result.rows[0];
  }

  async getUserCoins(userId) {
    const result = await pool.query(`SELECT coins FROM users WHERE id = $1`, [userId]);
    return result.rows[0]?.coins || 0;
  }

  async logClick(shopId, userId, clickType) {
    await pool.query(`INSERT INTO shop_clicks (shop_id, user_id, click_type) VALUES ($1, $2, $3)`, [
      shopId,
      userId,
      clickType,
    ]);
  }

  async getShopClicks(shopId) {
    const result = await pool.query(
      `
      SELECT sc.id, sc.click_type, sc.created_at, u.full_name as farmer_name, u.mobile as farmer_mobile
      FROM shop_clicks sc
      LEFT JOIN users u ON sc.user_id = u.id
      WHERE sc.shop_id = $1
      ORDER BY sc.created_at DESC
    `,
      [shopId]
    );
    return result.rows;
  }

  async getStats() {
    const result = await pool.query(`
      SELECT s.name as shop_name, sc.click_type, COUNT(*) as click_count, 
             u.full_name as farmer_name, u.mobile as farmer_mobile, MAX(sc.created_at) as last_click
      FROM shop_clicks sc
      JOIN shops s ON sc.shop_id = s.id
      LEFT JOIN users u ON sc.user_id = u.id
      GROUP BY s.name, sc.click_type, u.full_name, u.mobile
      ORDER BY last_click DESC
    `);
    return result.rows;
  }

  async redeemCoins(userId, shopId, coins = 50) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Deduct coins from user
      const updateResult = await client.query(
        `UPDATE users SET coins = coins - $1 WHERE id = $2 RETURNING coins`,
        [coins, userId]
      );
      if (updateResult.rows.length === 0) {
        throw new Error('User not found');
      }
      const newCoins = updateResult.rows[0].coins;

      // 2. Generate claim code
      const claimCode = `RS-5%-CLAIM-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

      // 3. Insert claim record
      const claimResult = await client.query(
        `INSERT INTO shop_coin_claims (user_id, shop_id, coins_redeemed, discount_percentage, claim_code)
         VALUES ($1, $2, $3, 5.0, $4) RETURNING *`,
        [userId, shopId, coins, claimCode]
      );

      await client.query('COMMIT');
      return { newCoins, claim: claimResult.rows[0] };
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async getAllCoinClaims() {
    const result = await pool.query(`
      SELECT scc.id, scc.coins_redeemed, scc.discount_percentage, scc.claim_code, scc.created_at,
             u.full_name as user_name, u.mobile as user_mobile,
             s.name as shop_name, s.city as shop_city
      FROM shop_coin_claims scc
      JOIN users u ON scc.user_id = u.id
      JOIN shops s ON scc.shop_id = s.id
      ORDER BY scc.created_at DESC
    `);
    return result.rows;
  }
}

module.exports = new ShopRepository();
