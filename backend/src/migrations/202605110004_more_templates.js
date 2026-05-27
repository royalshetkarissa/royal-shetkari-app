/**
 * Migration: 202605110004_more_templates
 * Purpose: Add templates for Tomato, Grapes and generic ones.
 */

exports.up = async (client) => {
  // 1. Tomato Templates
  const tomatoResult = await client.query(`SELECT id FROM crops WHERE name = 'Tomato' LIMIT 1`);
  if (tomatoResult.rows.length > 0) {
    const cropId = tomatoResult.rows[0].id;
    const templates = [
      [cropId, 1, 'Basal Dose', 'पायाभरणी खत', 'DAP - 50kg + MOP - 25kg'],
      [cropId, 20, 'Vegetative Growth', 'शाकीय वाढीसाठी खत', '19:19:19 - 5kg through fertigation'],
      [cropId, 40, 'Flowering Stage', 'फुलोरा अवस्था', '12:61:0 - 5kg'],
      [cropId, 60, 'Fruit Development', 'फळ फुगवण', '13:0:45 - 5kg'],
      [cropId, 80, 'Ripening Dose', 'फळ पिकवण्यासाठी खत', '0:0:50 - 5kg'],
    ];
    for (const t of templates) {
      await client.query(
        `INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, fertilizer_details) VALUES ($1, $2, $3, $4, $5)`,
        t
      );
    }
  }

  // 2. Grapes Templates
  const grapesResult = await client.query(`SELECT id FROM crops WHERE name = 'Grapes' LIMIT 1`);
  if (grapesResult.rows.length > 0) {
    const cropId = grapesResult.rows[0].id;
    const templates = [
      [cropId, 1, 'Pruning Dose', 'छाटणीनंतरचे खत', 'Super Phosphate - 100kg'],
      [cropId, 15, 'Sprouting Stage', 'फुटव्याची अवस्था', 'Urea - 50kg'],
      [cropId, 45, 'Berry Thinning', 'मणी विरळणी', 'GA3 Spray'],
      [cropId, 90, 'Brix Development', 'गोडी वाढवण्यासाठी', 'SOP - 50kg'],
    ];
    for (const t of templates) {
      await client.query(
        `INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, fertilizer_details) VALUES ($1, $2, $3, $4, $5)`,
        t
      );
    }
  }

  // 3. Add a generic template for ALL crops that don't have one
  const allCrops = await client.query(`SELECT id, marathi_name FROM crops`);
  for (const crop of allCrops.rows) {
    const check = await client.query(`SELECT 1 FROM crop_templates WHERE crop_id = $1`, [crop.id]);
    if (check.rows.length === 0) {
      // Generic basic schedule
      await client.query(
        `INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, fertilizer_details) 
        VALUES ($1, 1, 'Initial Fertilization', 'सुरुवातीची खत मात्रा', 'Basic NPK Dose')`,
        [crop.id]
      );
      await client.query(
        `INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, fertilizer_details) 
        VALUES ($1, 30, 'Mid-term Growth', 'मध्यम वाढीची मात्रा', 'Urea / Nitrogen Boost')`,
        [crop.id]
      );
    }
  }
};

exports.down = async (client) => {
  // Not strictly needed for this supplemental seed
};
