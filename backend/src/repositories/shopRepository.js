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
}

module.exports = new ShopRepository();
