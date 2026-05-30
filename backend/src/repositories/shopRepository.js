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
      coins_required = 50,
      discount_percentage = 5.0,
    } = data;
    const result = await pool.query(
      `INSERT INTO shops (name, profile_photo, address, contact_mobile, whatsapp_number, categories, images, latitude, longitude, owner_id, owner_name, services, pincode, city, redeem_coin_cost, discount_percentage) 
       VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16) RETURNING *`,
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
        coins_required,
        discount_percentage,
      ]
    );
    const row = result.rows[0];
    if (row) {
      row.coins_required = row.redeem_coin_cost;
    }
    return row;
  }

  async findAll(filters) {
    const { userLat, userLng, radius_km, sortBy, status = 'active' } = filters;

    let distanceSelect = '';
    const hasCoordinates = userLat !== undefined && userLat !== null && !isNaN(parseFloat(userLat)) &&
                           userLng !== undefined && userLng !== null && !isNaN(parseFloat(userLng));

    if (hasCoordinates) {
      distanceSelect = `, (6371 * acos(cos(radians($1)) * cos(radians(latitude)) * cos(radians(longitude) - radians($2)) + sin(radians($1)) * sin(radians(latitude)))) AS distance`;
    }

    let query = `
      SELECT * ${distanceSelect}
      FROM shops
      WHERE status = $3
    `;

    const params = [userLat || 0, userLng || 0, status];
    let paramIndex = 4;

    if (hasCoordinates && radius_km && !isNaN(parseFloat(radius_km))) {
      query += ` AND (6371 * acos(cos(radians($1)) * cos(radians(latitude)) * cos(radians(longitude) - radians($2)) + sin(radians($1)) * sin(radians(latitude)))) <= $${paramIndex}`;
      params.push(parseFloat(radius_km));
      paramIndex++;
    }

    // Sorting: default to distance ASC if coordinates are provided and sortBy is not specified
    if (sortBy === 'distance' || (!sortBy && hasCoordinates)) {
      query += ` ORDER BY distance ASC`;
    } else {
      query += ` ORDER BY created_at DESC`;
    }

    const result = await pool.query(query, params);
    result.rows.forEach(row => {
      if (row) row.coins_required = row.redeem_coin_cost;
    });
    return result.rows;
  }

  async findAdminShops() {
    const result = await pool.query(
      `SELECT * FROM shops WHERE status != 'deleted' ORDER BY created_at DESC`
    );
    result.rows.forEach(row => {
      if (row) row.coins_required = row.redeem_coin_cost;
    });
    return result.rows;
  }

  async updateStatus(id, status) {
    const result = await pool.query(
      `UPDATE shops SET status = $1, updated_at = NOW() WHERE id = $2 RETURNING *`,
      [status, id]
    );
    const row = result.rows[0];
    if (row) {
      row.coins_required = row.redeem_coin_cost;
    }
    return row;
  }

  async delete(id) {
    await pool.query(`UPDATE shops SET status = 'deleted' WHERE id = $1`, [id]);
  }

  async findById(id) {
    const result = await pool.query(`SELECT * FROM shops WHERE id = $1`, [id]);
    const row = result.rows[0];
    if (row) {
      row.coins_required = row.redeem_coin_cost;
    }
    return row;
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

  async redeemCoins(userId, shopId) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // Fetch dynamic coin offer and discount settings for this shop and lock the row to prevent concurrent modifications
      const shopRes = await client.query(
        'SELECT redeem_coin_cost, discount_percentage FROM shops WHERE id = $1 FOR UPDATE',
        [shopId]
      );
      if (shopRes.rows.length === 0) {
        throw new Error('Shop not found');
      }
      const coinsRequired = shopRes.rows[0].redeem_coin_cost || 50;
      const discountPercentage = parseFloat(shopRes.rows[0].discount_percentage) || 5.0;

      // Fetch and lock user row to prevent concurrency race conditions
      const userRes = await client.query(
        'SELECT coins FROM users WHERE id = $1 FOR UPDATE',
        [userId]
      );
      if (userRes.rows.length === 0) {
        throw new Error('User not found');
      }
      const userCoins = userRes.rows[0].coins || 0;
      if (userCoins < coinsRequired) {
        throw new Error(`Insufficient coins. Minimum ${coinsRequired} coins required for redemption.`);
      }

      // 1. Deduct coins from user
      const updateResult = await client.query(
        `UPDATE users SET coins = coins - $1 WHERE id = $2 RETURNING coins`,
        [coinsRequired, userId]
      );
      const newCoins = updateResult.rows[0].coins;

      // 2. Generate claim code
      const claimCode = `RS-${discountPercentage}%-CLAIM-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

      // 3. Insert claim record
      const claimResult = await client.query(
        `INSERT INTO shop_coin_claims (user_id, shop_id, coins_redeemed, discount_percentage, claim_code)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [userId, shopId, coinsRequired, discountPercentage, claimCode]
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

  async update(id, data) {
    const fields = [];
    const values = [];
    let queryIndex = 1;

    for (const [key, val] of Object.entries(data)) {
      if (val === undefined) continue; // Skip undefined values
      
      let dbKey = key;
      if (key === 'coins_required') dbKey = 'redeem_coin_cost';
      
      fields.push(`${dbKey} = $${queryIndex}`);
      if (key === 'categories' || key === 'images') {
        values.push(JSON.stringify(val));
      } else {
        values.push(val);
      }
      queryIndex++;
    }

    if (fields.length === 0) return null;

    values.push(id);
    const query = `UPDATE shops SET ${fields.join(', ')} WHERE id = $${queryIndex} RETURNING *`;
    const result = await pool.query(query, values);
    const row = result.rows[0];
    if (row) {
      row.coins_required = row.redeem_coin_cost;
    }
    return row;
  }
}

module.exports = new ShopRepository();
