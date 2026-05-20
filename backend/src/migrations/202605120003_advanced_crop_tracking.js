/**
 * Migration: 202605120003_advanced_crop_tracking
 * Purpose: Add harvest duration, expanded templates, and history preservation.
 */

exports.up = async (client) => {
  // 1. Add harvest duration to crops
  await client.query(`
    ALTER TABLE crops 
    ADD COLUMN IF NOT EXISTS harvest_days_min INTEGER DEFAULT 60,
    ADD COLUMN IF NOT EXISTS harvest_days_max INTEGER DEFAULT 90;
  `);

  // 2. Add status to journeys for history preservation
  await client.query(`
    DO $$ 
    BEGIN 
      IF NOT EXISTS (SELECT 1 FROM pg_type WHERE typname = 'journey_status') THEN
        CREATE TYPE journey_status AS ENUM ('active', 'completed', 'deleted');
      END IF;
    END $$;
  `);

  await client.query(`
    ALTER TABLE user_crop_journeys 
    ADD COLUMN IF NOT EXISTS status journey_status DEFAULT 'active';
  `);

  // 3. Update Crop Durations (Researched)
  const durations = {
    'Onion': [90, 120],
    'Tomato': [60, 80],
    'Cauliflower': [45, 60],
    'Chilli': [60, 90],
    'Cabbage': [60, 70],
    'Okra (Bhindi/Ladyfinger)': [45, 60],
    'Brinjal (Eggplant)': [60, 90],
    'Potato': [90, 110],
    'Cucumber': [40, 50],
    'Grapes': [120, 150]
  };

  for (const [name, [min, max]] of Object.entries(durations)) {
    await client.query(`UPDATE crops SET harvest_days_min = $1, harvest_days_max = $2 WHERE name = $3`, [min, max, name]);
  }

  // 4. Advanced Templates (Sequential English-first)
  // Clear and re-seed for these specific crops
  const cropsToSeed = ['Cauliflower', 'Tomato', 'Onion'];
  
  for (const cropName of cropsToSeed) {
    const cropId = (await client.query(`SELECT id FROM crops WHERE name = $1`, [cropName])).rows[0].id;
    await client.query(`DELETE FROM crop_templates WHERE crop_id = $1`, [cropId]);
    
    let templateData = [];
    if (cropName === 'Cauliflower') {
      templateData = [
        [1, 'Nursery Management', 'रोपवाटिका व्यवस्थापन', 'Apply Neem Cake + Trichoderma', 'FYM + NPK 19:19:19'],
        [10, 'Transplanting', 'पुनर्लागवड', 'Drenching with Humic Acid', '10:26:26 (50kg/acre)'],
        [20, 'Vegetative Growth', 'शाकीय वाढ', 'Jivamrut Spray', 'Urea (25kg) + Micronutrients'],
        [30, 'Curd Initiation', 'गड्डा येण्याची अवस्था', 'Boron (20%) spray', '12:61:00 (5kg)'],
        [45, 'Harvesting Stage', 'काढणी अवस्था', 'Check for curd firmness', 'SOP (0:0:50) for quality']
      ];
    } else if (cropName === 'Tomato') {
      templateData = [
        [1, 'Land Preparation', 'जमीन तयार करणे', 'Organic Manure (10 tons)', 'Basal Dose: DAP + MOP'],
        [15, 'Establishment', 'मुळांची वाढ', 'Seaweed Extract', 'Humic Acid + 19:19:19'],
        [35, 'Early Flowering', 'सुरुवातीचा फुलोरा', 'Panchagavya Spray', '12:61:00 (MAP)'],
        [55, 'Fruit Setting', 'फळ धारणा', 'Egg + Lemon Juice Spray', '13:0:45 (Multi-K)'],
        [75, 'Harvest Start', 'काढणी सुरुवात', 'Maintain soil moisture', '0:0:50 for fruit shine']
      ];
    } else if (cropName === 'Onion') {
      templateData = [
        [1, 'Base Dose', 'पायाभरणी', 'Neem Cake + Castor Cake', 'DAP + Sulphur + Zinc'],
        [30, 'Neck Development', 'मान फुगवण', 'Dashparni Ark spray', 'Urea + Micronutrient Mixture'],
        [60, 'Bulb Initiation', 'कांदा धरण्याची अवस्था', 'Potash rich organic manure', '0:52:34 (5kg)'],
        [90, 'Bulb Enlargement', 'कांदा फुगवण', 'Wood Ash application', '13:0:45 + Boron'],
        [110, 'Pre-Harvesting', 'काढणीपूर्व तयारी', 'Stop watering 15 days before', 'No chemical fertilizers']
      ];
    }

    for (const d of templateData) {
      await client.query(`
        INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, organic_details, chemical_details)
        VALUES ($1, $2, $3, $4, $5, $6)`, [cropId, ...d]);
    }
  }
};

exports.down = async (client) => {
  // Not rolling back types to avoid data loss issues
};
