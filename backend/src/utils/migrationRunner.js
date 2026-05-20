const fs = require('fs');
const path = require('path');
const pool = require('../config/db');
const logger = require('./logger');

/**
 * Robust Migration Runner with Rollback support.
 */
class MigrationRunner {
  async init() {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS migrations_meta (
        id SERIAL PRIMARY KEY,
        version VARCHAR(50) UNIQUE NOT NULL,
        name VARCHAR(255) NOT NULL,
        applied_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
  }

  async up() {
    await this.init();
    const migrationsDir = path.join(__dirname, '../migrations');
    if (!fs.existsSync(migrationsDir)) fs.mkdirSync(migrationsDir);

    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.endsWith('.js'))
      .sort();

    for (const file of files) {
      const version = file.split('_')[0];
      const check = await pool.query('SELECT 1 FROM migrations_meta WHERE version = $1', [version]);
      
      if (check.rows.length === 0) {
        logger.info(`Applying migration: ${file}`);
        const migration = require(path.join(migrationsDir, file));
        
        const client = await pool.connect();
        try {
          await client.query('BEGIN');
          await migration.up(client);
          await client.query('INSERT INTO migrations_meta (version, name) VALUES ($1, $2)', [version, file]);
          await client.query('COMMIT');
          logger.info(`✅ Successfully applied: ${file}`);
        } catch (err) {
          await client.query('ROLLBACK');
          logger.error(`❌ Failed to apply migration ${file}: ${err.message}`);
          throw err;
        } finally {
          client.release();
        }
      }
    }
  }

  async down(version) {
    const migrationsDir = path.join(__dirname, '../migrations');
    const files = fs.readdirSync(migrationsDir)
      .filter(f => f.startsWith(version) && f.endsWith('.js'));

    if (files.length === 0) throw new Error(`Migration version ${version} not found.`);

    const file = files[0];
    logger.info(`Rolling back migration: ${file}`);
    const migration = require(path.join(migrationsDir, file));

    const client = await pool.connect();
    try {
      await client.query('BEGIN');
      await migration.down(client);
      await client.query('DELETE FROM migrations_meta WHERE version = $1', [version]);
      await client.query('COMMIT');
      logger.info(`✅ Successfully rolled back: ${file}`);
    } catch (err) {
      await client.query('ROLLBACK');
      logger.error(`❌ Failed to rollback migration ${file}: ${err.message}`);
      throw err;
    } finally {
      client.release();
    }
  }
}

module.exports = new MigrationRunner();
