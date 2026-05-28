/**
 * Migration: 202605290001_shop_coin_redemptions
 * Purpose: Schema for Shop Coin Claims to track 5% discounts.
 */

exports.up = async (client) => {
  await client.query(`
    CREATE TABLE IF NOT EXISTS shop_coin_claims (
      id SERIAL PRIMARY KEY,
      shop_id INTEGER REFERENCES shops(id) ON DELETE CASCADE,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      coins_redeemed INTEGER DEFAULT 50,
      discount_percentage NUMERIC DEFAULT 5.0,
      claim_code VARCHAR(50) NOT NULL UNIQUE,
      created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    );

    CREATE INDEX IF NOT EXISTS idx_shop_coin_claims_shop ON shop_coin_claims(shop_id);
    CREATE INDEX IF NOT EXISTS idx_shop_coin_claims_user ON shop_coin_claims(user_id);
  `);
};

exports.down = async (client) => {
  await client.query(`DROP TABLE IF EXISTS shop_coin_claims CASCADE;`);
};
