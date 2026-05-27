/**
 * Migration: 202605120006_ultra_detailed_timetable
 * Purpose: Add "Why" and "What" information to each growth stage.
 */

exports.up = async (client) => {
  // 1. Add rationale and content columns
  await client.query(`
    ALTER TABLE crop_templates 
    ADD COLUMN IF NOT EXISTS rationale_marathi TEXT,
    ADD COLUMN IF NOT EXISTS rationale_english TEXT,
    ADD COLUMN IF NOT EXISTS nutrient_content TEXT;

    ALTER TABLE user_crop_tasks
    ADD COLUMN IF NOT EXISTS rationale_marathi TEXT,
    ADD COLUMN IF NOT EXISTS rationale_english TEXT,
    ADD COLUMN IF NOT EXISTS nutrient_content TEXT;
  `);

  // 2. Ultra-Detailed Seed Data for Cauliflower (45-60 days)
  const cauliflowerId = (await client.query(`SELECT id FROM crops WHERE name = 'Cauliflower'`))
    .rows[0].id;
  await client.query(`DELETE FROM crop_templates WHERE crop_id = $1`, [cauliflowerId]);

  const steps = [
    [
      0,
      'Farm Preparation',
      'मशागत',
      'To prepare loose soil for aeration and root penetration',
      'माती भुसभुशीत करण्यासाठी आणि मुळांच्या वाढीसाठी',
      'FYM (10 tons) + Trichoderma viride',
      'Organic Carbon & Bio-fungicides',
    ],
    [
      1,
      'Nursery Sowing',
      'रोपवाटिका पेरणी',
      'To grow healthy, disease-free seedlings in a controlled area',
      'निरोगी आणि जोमदार रोपे तयार करण्यासाठी',
      'Coco-peat + Pro-tray sowing',
      'Light weight media for germination',
    ],
    [
      7,
      'Seedling Treatment',
      'रोप प्रक्रिया',
      'To prevent soil-borne diseases after transplanting',
      'मातीतील बुरशीजन्य रोगांपासून संरक्षण करण्यासाठी',
      'Dip roots in Humic Acid + Fungicide',
      'Humic Acid (Rooting agent) + Carbendazim',
    ],
    [
      10,
      'Transplanting',
      'पुनर्लागवड',
      'To establish the plant in the main field with proper spacing',
      'मुख्य शेतात रोपांची लागवड करण्यासाठी',
      'Spacing 45cm x 45cm with watering',
      'Initial water requirement',
    ],
    [
      15,
      'Root Establishment',
      'मुळांची वाढ',
      'To promote early root branching and soil grip',
      'पांढऱ्या मुळांच्या वाढीसाठी आणि जमिनीची पकड मजबूत करण्यासाठी',
      'Jeevamrut drenching',
      'Natural growth promoters & Bacteria',
    ],
    [
      22,
      'First Top Dressing',
      'पहिली मात्रा',
      'To support rapid leaf growth (Vegetative phase)',
      'शाकीय वाढ आणि पानांच्या विकासासाठी',
      'Neem Cake + Earthworm compost',
      'Nitrogen (Urea 25kg) + Micronutrients',
    ],
    [
      30,
      'Gap Filling/Weeding',
      'नांग्या भरणे आणि निंदणी',
      'To remove competition for nutrients and maintain plant count',
      'तण काढण्यासाठी आणि पिकातील अंतर राखण्यासाठी',
      'Manual weeding',
      'Nutrient preservation',
    ],
    [
      38,
      'Curd Initiation',
      'गड्डा येण्याची अवस्था',
      'To provide essential Boron for curd firmness and color',
      'गड्डा पांढरा आणि घट्ट राहण्यासाठी बोरोनची आवश्यकता',
      'Boron (20%) spray',
      'Boron + Calcium',
    ],
    [
      45,
      'Head Development',
      'गड्डा विकास',
      'To increase the weight and size of the cauliflower head',
      'गड्ड्याचे वजन आणि आकार वाढवण्यासाठी',
      'Spray Seaweed Extract',
      'Potash (0:0:50) + Boron',
    ],
    [
      52,
      'Pre-Harvest Polish',
      'काढणीपूर्वीची काळजी',
      'To maintain freshness and prevent sun-scald',
      'गड्डा स्वच्छ आणि पांढरा राहण्यासाठी',
      'Cover heads with leaves (Blanching)',
      'UV protection',
    ],
    [
      60,
      'Harvesting',
      'काढणी',
      'To pick at peak maturity for maximum market value',
      'योग्य पक्वतेवर काढणी करून चांगला भाव मिळवण्यासाठी',
      'Harvest early morning',
      'Peak quality preservation',
    ],
  ];

  for (const [offset, name, marathi, whyEng, whyMar, dose, nutrients] of steps) {
    await client.query(
      `
      INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, rationale_english, rationale_marathi, organic_details, nutrient_content)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8)`,
      [cauliflowerId, offset, name, marathi, whyEng, whyMar, dose, nutrients]
    );
  }
};

exports.down = async (client) => {
  // Optional cleanup
};
