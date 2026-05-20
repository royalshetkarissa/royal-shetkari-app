/**
 * Migration: 202605110003_advanced_timetable
 * Purpose: Setup tables for the advanced crop timetable and gamification system.
 */

exports.up = async (client) => {
  // 1. Create Crops Metadata Table
  await client.query(`
    CREATE TABLE IF NOT EXISTS crops (
      id SERIAL PRIMARY KEY,
      name VARCHAR(100) NOT NULL,
      marathi_name VARCHAR(100) NOT NULL,
      category VARCHAR(50) NOT NULL, -- 'Vegetable', 'Fruit'
      icon_name VARCHAR(50), -- Flutter Material Icon name
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  // 2. Create Crop Templates Table
  await client.query(`
    CREATE TABLE IF NOT EXISTS crop_templates (
      id SERIAL PRIMARY KEY,
      crop_id INTEGER REFERENCES crops(id) ON DELETE CASCADE,
      day_offset INTEGER NOT NULL,
      task_name VARCHAR(255) NOT NULL,
      task_marathi VARCHAR(255) NOT NULL,
      fertilizer_details TEXT,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  // 3. Create User Crop Journeys Table
  await client.query(`
    CREATE TABLE IF NOT EXISTS user_crop_journeys (
      id SERIAL PRIMARY KEY,
      user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
      crop_id INTEGER REFERENCES crops(id) ON DELETE CASCADE,
      planting_date DATE NOT NULL,
      is_active BOOLEAN DEFAULT TRUE,
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  // 4. Create User Tasks Tracking Table
  await client.query(`
    CREATE TABLE IF NOT EXISTS user_crop_tasks (
      id SERIAL PRIMARY KEY,
      user_crop_id INTEGER REFERENCES user_crop_journeys(id) ON DELETE CASCADE,
      template_id INTEGER REFERENCES crop_templates(id) ON DELETE SET NULL,
      task_name VARCHAR(255) NOT NULL,
      task_marathi VARCHAR(255) NOT NULL,
      due_date DATE NOT NULL,
      is_completed BOOLEAN DEFAULT FALSE,
      completed_at TIMESTAMPTZ,
      coin_awarded BOOLEAN DEFAULT FALSE,
      created_at TIMESTAMPTZ DEFAULT NOW(),
      UNIQUE(user_crop_id, template_id) -- Prevent duplicate tasks for the same template
    )
  `);

  // 5. Add Coins to Users Table
  await client.query(`
    ALTER TABLE users ADD COLUMN IF NOT EXISTS coins INTEGER DEFAULT 0;
  `);

  // 6. Seed Crops Data
  const crops = [
    ['Onion', 'कांदा', 'Vegetable', 'grass'],
    ['Tomato', 'टोमॅटो', 'Vegetable', 'apple'],
    ['Potato', 'बटाटा', 'Vegetable', 'circle'],
    ['Brinjal', 'वांगी', 'Vegetable', 'egg'],
    ['Okra', 'भेंडी', 'Vegetable', 'spa'],
    ['Cabbage', 'कोबी', 'Vegetable', 'eco'],
    ['Cauliflower', 'फ्लॉवर', 'Vegetable', 'eco'],
    ['Chilli', 'मिरची', 'Vegetable', 'bolt'],
    ['Garlic', 'लसूण', 'Vegetable', 'grain'],
    ['Ginger', 'आले', 'Vegetable', 'grain'],
    ['Spinach', 'पालक', 'Vegetable', 'eco'],
    ['Fenugreek', 'मेथी', 'Vegetable', 'eco'],
    ['Coriander', 'कोथिंबीर', 'Vegetable', 'eco'],
    ['Grapes', 'द्राक्षे', 'Fruit', 'bubble_chart'],
    ['Pomegranate', 'डाळिंब', 'Fruit', 'radio_button_checked'],
    ['Mango', 'आंबा', 'Fruit', 'favorite'],
    ['Banana', 'केळी', 'Fruit', 'straighten'],
    ['Orange', 'संत्री', 'Fruit', 'brightness_high'],
    ['Strawberry', 'स्ट्रॉबेरी', 'Fruit', 'favorite_border']
  ];

  for (const crop of crops) {
    await client.query(
      `INSERT INTO crops (name, marathi_name, category, icon_name) VALUES ($1, $2, $3, $4)`,
      crop
    );
  }

  // 7. Seed Sample Template for Onion
  const onionIdResult = await client.query(`SELECT id FROM crops WHERE name = 'Onion' LIMIT 1`);
  if (onionIdResult.rows.length > 0) {
    const onionId = onionIdResult.rows[0].id;
    const templates = [
      [onionId, 1, 'Basal Dose', 'पायाभरणी खत', 'NPK 10:26:26 - 50kg'],
      [onionId, 15, 'First Top Dressing', 'पहिली खत मात्रा', 'Urea - 25kg'],
      [onionId, 30, 'Second Top Dressing', 'दुसरी खत मात्रा', 'Urea - 25kg + MOP - 20kg'],
      [onionId, 45, 'Micronutrient Spray', 'सूक्ष्म अन्नद्रव्य फवारणी', 'Grade 2 Micronutrients'],
      [onionId, 60, 'Bulb Development Dose', 'कांदा फुगवणीसाठी खत', '0:0:50 - 5kg through fertigation']
    ];
    for (const t of templates) {
      await client.query(
        `INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, fertilizer_details) VALUES ($1, $2, $3, $4, $5)`,
        t
      );
    }
  }
};

exports.down = async (client) => {
  await client.query(`DROP TABLE IF EXISTS user_crop_tasks`);
  await client.query(`DROP TABLE IF EXISTS user_crop_journeys`);
  await client.query(`DROP TABLE IF EXISTS crop_templates`);
  await client.query(`DROP TABLE IF EXISTS crops`);
  await client.query(`ALTER TABLE users DROP COLUMN IF EXISTS coins`);
};
