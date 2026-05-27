/**
 * Migration: 202605120001_organic_chemical_timetable
 * Purpose: Update templates to support Organic and Chemical options.
 */

exports.up = async (client) => {
  // 1. Add organic/chemical columns if they don't exist
  await client.query(`
    ALTER TABLE crop_templates 
    ADD COLUMN IF NOT EXISTS organic_details TEXT,
    ADD COLUMN IF NOT EXISTS chemical_details TEXT;
  `);

  // 2. Clear existing templates to re-seed with advanced data
  await client.query(`TRUNCATE crop_templates CASCADE`);

  // 3. Researched Data for Onion
  const onionId = (await client.query(`SELECT id FROM crops WHERE name = 'Onion'`)).rows[0].id;
  const onionData = [
    [
      onionId,
      1,
      'Basal Dose',
      'पायाभरणी खत',
      'FYM (शेणखत) - 10 tons/acre + Neem Cake',
      'DAP - 50kg + MOP - 25kg',
    ],
    [
      onionId,
      20,
      'First Growth Phase',
      'पहिली वाढीची अवस्था',
      'Humic Acid + Seaweed Extract',
      'Urea - 25kg + Sulphur - 10kg',
    ],
    [
      onionId,
      45,
      'Bulb Development',
      'कांदा फुगवण अवस्था',
      'Vermicompost + Potash (Organic)',
      '0:0:50 - 5kg + Boron',
    ],
    [
      onionId,
      60,
      'Final Maturity',
      'अंतिम परिपक्वता',
      'Wood Ash (राख) spray',
      '0:52:34 - 5kg through fertigation',
    ],
  ];

  // 4. Researched Data for Tomato
  const tomatoId = (await client.query(`SELECT id FROM crops WHERE name = 'Tomato'`)).rows[0].id;
  const tomatoData = [
    [
      tomatoId,
      1,
      'Planting Dose',
      'लागवड खत',
      'Compost + Trichoderma',
      '10:26:26 - 50kg + Micronutrients',
    ],
    [
      tomatoId,
      25,
      'Vegetative Stage',
      'वाढीची अवस्था',
      'Jivamrut (जीवामृत) every 15 days',
      '19:19:19 - 5kg + Urea',
    ],
    [tomatoId, 50, 'Flowering Stage', 'फुलोरा अवस्था', 'Panchagavya spray', '12:61:00 (MAP) - 5kg'],
    [
      tomatoId,
      75,
      'Fruit Filling',
      'फळ फुगवण',
      'Banana Peel Liquid Fertilizer',
      '13:0:45 (Multi-K) - 5kg',
    ],
  ];

  for (const d of [...onionData, ...tomatoData]) {
    await client.query(
      `
      INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, organic_details, chemical_details)
      VALUES ($1, $2, $3, $4, $5, $6)`,
      d
    );
  }

  // 5. Generic schedule for others
  const otherCrops = (
    await client.query(`SELECT id FROM crops WHERE id NOT IN ($1, $2)`, [onionId, tomatoId])
  ).rows;
  for (const crop of otherCrops) {
    await client.query(
      `
      INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, organic_details, chemical_details)
      VALUES ($1, 1, 'Starting Dose', 'सुरुवातीची मात्रा', 'Organic Compost + Bio-fertilizers', 'NPK 19:19:19 Basic Dose'),
             ($1, 30, 'Growth Support', 'वाढ आधार', 'Seaweed spray', 'Urea / Nitrogen Top Dressing')`,
      [crop.id]
    );
  }
};

exports.down = async (client) => {
  await client.query(
    `ALTER TABLE crop_templates DROP COLUMN IF EXISTS organic_details, DROP COLUMN IF EXISTS chemical_details`
  );
};
