/**
 * Migration: 202605120004_full_timetable_expansion
 * Purpose: Provide 8-10 professional growth steps for all major crops.
 */

exports.up = async (client) => {
  const crops = (await client.query(`SELECT id, name FROM crops`)).rows;

  for (const crop of crops) {
    // Clear old templates for these crops to ensure "Full Timetable"
    await client.query(`DELETE FROM crop_templates WHERE crop_id = $1`, [crop.id]);

    let steps = [];

    if (crop.name === 'Cauliflower' || crop.name === 'Cabbage') {
      steps = [
        [
          0,
          'Land Preparation',
          'जमीन तयार करणे',
          'Mix 5 tons FYM with 2kg Trichoderma',
          'Apply Basal Dose: DAP 50kg + MOP 25kg',
        ],
        [
          1,
          'Seedling Treatment',
          'रोप प्रक्रिया',
          'Dip roots in Beejamrut for 30 mins',
          'Dip roots in Carbendazim (2g/L)',
        ],
        [
          7,
          'Transplanting',
          'पुनर्लागवड',
          'Ensure soil moisture with Jeevamrut',
          'Apply 10:26:26 (25kg/acre)',
        ],
        [
          15,
          'Gap Filling & Weeding',
          'नांग्या भरणे आणि निंदणी',
          'Hand weeding and mulch with straw',
          'Spray Quizalofop-ethyl for weeds',
        ],
        [
          25,
          'Vegetative Boost',
          'शाकीय वाढ जोम',
          'Spray Fish Amino Acid (3ml/L)',
          'Urea 25kg + Micronutrient mix',
        ],
        [
          40,
          'Curd/Head Initiation',
          'गड्डा तयार होण्याची सुरुवात',
          'Spray Boron (20%) 1g/L',
          'Apply 12:61:00 (5kg via fertigation)',
        ],
        [
          55,
          'Head Development',
          'गड्डा विकास',
          'Spray Dashparni Ark (5%)',
          '0:52:34 (5kg) + Calcium Nitrate (5kg)',
        ],
        [
          70,
          'Harvesting',
          'काढणी',
          'Grade based on size/firmness',
          'Pre-cooling if transporting long distance',
        ],
      ];
    } else if (crop.name === 'Tomato' || crop.name === 'Chilli' || crop.name === 'Brinjal') {
      steps = [
        [
          0,
          'Bed Preparation',
          'वाफे तयार करणे',
          'Add Vermicompost + Neem Cake',
          'Basal: 10:26:26 (50kg) + Carbofuran',
        ],
        [10, 'Planting', 'लागवड', 'Water with Humic Acid (Liquid)', 'Drench with 19:19:19 (5g/L)'],
        [
          25,
          'Branching Stage',
          'फांद्या फुटण्याची अवस्था',
          'Spray Panchagavya (3%)',
          'Urea 20kg + Magnesium Sulphate 10kg',
        ],
        [
          40,
          'Flowering Initiation',
          'फुलोरा सुरुवात',
          'Spray Seaweed Extract',
          'Spray 12:61:00 (5g/L) + NAA 1ml/10L',
        ],
        [
          55,
          'Fruit Setting',
          'फळ धारणा',
          'Spray Egg-Lemon tonic',
          'Spray 0:52:34 + Micronutrients',
        ],
        [
          70,
          'Early Fruiting',
          'सुरुवातीची फळे',
          'Maintain staking/support',
          'Apply 13:0:45 (5kg via drip)',
        ],
        [85, 'Main Harvest', 'मुख्य काढणी', 'Pick early morning', '0:0:50 for fruit shine'],
        [100, 'Late Harvest', 'उशिराची काढणी', 'Maintain irrigation', 'SOP (5kg) to maintain size'],
      ];
    } else if (crop.name === 'Onion' || crop.name === 'Garlic') {
      steps = [
        [0, 'Soil prep', 'मशागत', 'Deep ploughing + FYM', 'DAP 50kg + Sulphur 10kg'],
        [15, 'Establishment', 'मुळांची वाढ', 'Jeevamrut drenching', '19:19:19 (5kg via drip)'],
        [
          35,
          'Vegetative phase',
          'शाकीय वाढ',
          'Dashparni Ark spray',
          'Urea 25kg + Zinc Sulphate 5kg',
        ],
        [
          55,
          'Bulb Initiation',
          'कांदा धरण्याची अवस्था',
          'Wood Ash application',
          '0:52:34 (5kg) + Boron',
        ],
        [
          75,
          'Bulb Enlargement',
          'कांदा फुगवण',
          'Spray Potash rich liquid organic',
          '13:0:45 (5kg)',
        ],
        [95, 'Bulb Maturity', 'कांदा पक्वता', 'Reduce watering', '0:0:50 (5kg)'],
        [
          110,
          'Pre-harvesting',
          'काढणीपूर्व',
          'Stop watering 15 days before',
          'Check for neck fall (50%)',
        ],
        [
          120,
          'Harvest & Curing',
          'काढणी आणि सुकवणी',
          'Dry in shade for 3-4 days',
          'Grade and store in ventilated area',
        ],
      ];
    } else {
      // Default Advanced Schedule for other crops
      steps = [
        [0, 'Pre-sowing', 'पेरणीपूर्व', 'Organic Manure 2 tons', 'Basal NPK Dose'],
        [
          10,
          'Germination/Establishment',
          'रुजवण/मुळांची वाढ',
          'Humic Acid treatment',
          '19:19:19 Starter',
        ],
        [25, 'Early Growth', 'सुरुवातीची वाढ', 'Seaweed Spray', 'Nitrogen Top Dose'],
        [45, 'Flowering Stage', 'फुलोरा अवस्था', 'Panchagavya Spray', '12:61:00 Boost'],
        [
          60,
          'Fruiting/Bulbing',
          'फळ/कांदा विकास',
          'Potash rich organic drench',
          '0:52:34 Development',
        ],
        [75, 'Maturity Stage', 'पक्वता अवस्था', 'Maintain moisture', '13:0:45 Quality boost'],
        [90, 'Pre-harvest', 'काढणीपूर्व', 'Check quality markers', '0:0:50 Finish'],
        [100, 'Harvesting', 'काढणी', 'Proper handling', 'Marketing prep'],
      ];
    }

    for (const [offset, name, marathi, organic, chemical] of steps) {
      await client.query(
        `
        INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, organic_details, chemical_details)
        VALUES ($1, $2, $3, $4, $5, $6)`,
        [crop.id, offset, name, marathi, organic, chemical]
      );
    }
  }
};

exports.down = async (client) => {
  // Optional cleanup
};
