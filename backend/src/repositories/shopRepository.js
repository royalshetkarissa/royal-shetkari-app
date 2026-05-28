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
      redeem_coin_cost,
      discount_percentage,
    } = data;

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      const result = await client.query(
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
          redeem_coin_cost !== undefined ? parseInt(redeem_coin_cost) : 50,
          discount_percentage !== undefined ? parseFloat(discount_percentage) : 5.0,
        ]
      );
      const shop = result.rows[0];

      // Insert audit log for registration
      await client.query(
        `INSERT INTO shop_audit_logs (shop_id, changed_by_user_id, field_name, old_value, new_value) 
         VALUES ($1, $2, $3, $4, $5)`,
        [shop.id, ownerId, 'registration', null, 'registered']
      );

      await client.query('COMMIT');
      return shop;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async update(id, data, changedByUserId) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      const oldResult = await client.query('SELECT * FROM shops WHERE id = $1', [id]);
      if (oldResult.rows.length === 0) {
        throw new Error('Shop not found');
      }
      const oldShop = oldResult.rows[0];

      const updates = [];
      const values = [];
      let valIdx = 1;

      const auditLogs = [];

      const fieldsToCompare = [
        { key: 'name', type: 'string' },
        { key: 'owner_name', type: 'string' },
        { key: 'address', type: 'string' },
        { key: 'contact_mobile', type: 'string' },
        { key: 'whatsapp_number', type: 'string' },
        { key: 'services', type: 'string' },
        { key: 'pincode', type: 'string' },
        { key: 'city', type: 'string' },
        { key: 'status', type: 'string' },
        { key: 'redeem_coin_cost', type: 'integer' },
        { key: 'discount_percentage', type: 'numeric' },
        { key: 'latitude', type: 'numeric' },
        { key: 'longitude', type: 'numeric' },
      ];

      for (const field of fieldsToCompare) {
        const { key, type } = field;
        if (data[key] !== undefined) {
          let newVal = data[key];
          let oldVal = oldShop[key];

          if (type === 'integer') {
            newVal = parseInt(newVal);
            oldVal = oldVal ? parseInt(oldVal) : 0;
          } else if (type === 'numeric') {
            newVal = parseFloat(newVal);
            oldVal = oldVal ? parseFloat(oldVal) : 0.0;
          } else if (type === 'string') {
            newVal = newVal ? newVal.toString().trim() : '';
            oldVal = oldVal ? oldVal.toString().trim() : '';
          }

          if (newVal !== oldVal) {
            updates.push(`${key} = $${valIdx}`);
            values.push(newVal);
            valIdx++;

            auditLogs.push({
              field_name: key,
              old_value: oldShop[key] !== null ? oldShop[key].toString() : null,
              new_value: newVal !== null ? newVal.toString() : null,
            });
          }
        }
      }

      // Compare categories
      if (data.categories !== undefined) {
        const newCats = Array.isArray(data.categories) ? [...data.categories].sort() : [];
        const oldCats = Array.isArray(oldShop.categories) ? [...oldShop.categories].sort() : [];
        if (JSON.stringify(newCats) !== JSON.stringify(oldCats)) {
          updates.push(`categories = $${valIdx}`);
          values.push(JSON.stringify(newCats));
          valIdx++;

          auditLogs.push({
            field_name: 'categories',
            old_value: JSON.stringify(oldCats),
            new_value: JSON.stringify(newCats),
          });
        }
      }

      // Compare profile_photo (only if a new one is uploaded/provided)
      if (data.profile_photo) {
        if (data.profile_photo !== oldShop.profile_photo) {
          updates.push(`profile_photo = $${valIdx}`);
          values.push(data.profile_photo);
          valIdx++;

          auditLogs.push({
            field_name: 'profile_photo',
            old_value: oldShop.profile_photo,
            new_value: data.profile_photo,
          });
        }
      }

      // Compare images (only if new images are uploaded/provided)
      if (data.images && data.images.length > 0) {
        const newImgs = [...data.images].sort();
        const oldImgs = Array.isArray(oldShop.images) ? [...oldShop.images].sort() : [];
        if (JSON.stringify(newImgs) !== JSON.stringify(oldImgs)) {
          updates.push(`images = $${valIdx}`);
          values.push(JSON.stringify(newImgs));
          valIdx++;

          auditLogs.push({
            field_name: 'images',
            old_value: JSON.stringify(oldImgs),
            new_value: JSON.stringify(newImgs),
          });
        }
      }

      if (updates.length > 0) {
        values.push(id);
        const query = `UPDATE shops SET ${updates.join(', ')}, updated_at = NOW() WHERE id = $${valIdx} RETURNING *`;
        const updateRes = await client.query(query, values);

        // Insert audit logs
        for (const log of auditLogs) {
          await client.query(
            `INSERT INTO shop_audit_logs (shop_id, changed_by_user_id, field_name, old_value, new_value)
              VALUES ($1, $2, $3, $4, $5)`,
            [id, changedByUserId, log.field_name, log.old_value, log.new_value]
          );
        }

        await client.query('COMMIT');
        return updateRes.rows[0];
      }

      await client.query('COMMIT');
      return oldShop;
    } catch (err) {
      await client.query('ROLLBACK');
      throw err;
    } finally {
      client.release();
    }
  }

  async getAuditLogs() {
    const result = await pool.query(`
      SELECT al.id, al.shop_id, al.changed_by_user_id, al.field_name, al.old_value, al.new_value, al.created_at,
             s.name as shop_name, u.full_name as changer_name, u.mobile as changer_mobile
      FROM shop_audit_logs al
      JOIN shops s ON al.shop_id = s.id
      LEFT JOIN users u ON al.changed_by_user_id = u.id
      ORDER BY al.created_at DESC
    `);
    return result.rows;
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

  async redeemCoins(userId, shopId) {
    const client = await pool.connect();
    try {
      await client.query('BEGIN');

      // 1. Get the shop's configured coins and discount
      const shopRes = await client.query(
        'SELECT redeem_coin_cost, discount_percentage FROM shops WHERE id = $1',
        [shopId]
      );
      if (shopRes.rows.length === 0) {
        throw new Error('Shop not found');
      }
      const coinCost =
        shopRes.rows[0].redeem_coin_cost !== null ? parseInt(shopRes.rows[0].redeem_coin_cost) : 50;
      const discount =
        shopRes.rows[0].discount_percentage !== null
          ? parseFloat(shopRes.rows[0].discount_percentage)
          : 5.0;

      // 2. Deduct coins from user
      const updateResult = await client.query(
        `UPDATE users SET coins = coins - $1 WHERE id = $2 RETURNING coins`,
        [coinCost, userId]
      );
      if (updateResult.rows.length === 0) {
        throw new Error('User not found');
      }
      const newCoins = updateResult.rows[0].coins;

      // 3. Generate claim code
      const claimCode = `RS-${parseInt(discount)}%-CLAIM-${Math.random().toString(36).substring(2, 8).toUpperCase()}`;

      // 4. Insert claim record
      const claimResult = await client.query(
        `INSERT INTO shop_coin_claims (user_id, shop_id, coins_redeemed, discount_percentage, claim_code)
         VALUES ($1, $2, $3, $4, $5) RETURNING *`,
        [userId, shopId, coinCost, discount, claimCode]
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

  async getFeaturedShopForDate(dateStr) {
    const result = await pool.query(
      `SELECT fss.*, s.name as shop_name, s.owner_name, s.contact_mobile, s.address, s.profile_photo, s.images, s.redeem_coin_cost, s.discount_percentage, s.city, s.pincode
       FROM featured_shop_schedules fss
       JOIN shops s ON fss.shop_id = s.id
       WHERE fss.featured_date = $1`,
      [dateStr]
    );
    return result.rows[0];
  }

  async createFeaturedSchedule(shopId, dateStr, isNewArrival) {
    const result = await pool.query(
      `INSERT INTO featured_shop_schedules (shop_id, featured_date, is_new_arrival)
       VALUES ($1, $2, $3)
       RETURNING *`,
      [shopId, dateStr, isNewArrival]
    );
    return result.rows[0];
  }

  async getLastScheduledEntry() {
    const result = await pool.query(
      `SELECT * FROM featured_shop_schedules ORDER BY featured_date DESC LIMIT 1`
    );
    return result.rows[0];
  }

  async getFeaturedHistory() {
    const result = await pool.query(
      `SELECT fss.id, fss.featured_date, fss.is_new_arrival, fss.created_at,
              s.name as shop_name, s.owner_name, s.city
       FROM featured_shop_schedules fss
       JOIN shops s ON fss.shop_id = s.id
       ORDER BY fss.featured_date DESC`
    );
    return result.rows;
  }

  async getActiveShopsSorted() {
    const result = await pool.query(
      `SELECT * FROM shops WHERE status = 'active' ORDER BY id ASC`
    );
    return result.rows;
  }

  async getNewArrivalShop() {
    const result = await pool.query(
      `SELECT * FROM shops 
       WHERE status = 'active' AND created_at >= NOW() - INTERVAL '24 hours'
       ORDER BY created_at DESC LIMIT 1`
    );
    return result.rows[0];
  }
}

module.exports = new ShopRepository();
