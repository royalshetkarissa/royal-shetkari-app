/**
 * Migration: 202606040001_crop_diseases_icrisat
 * Purpose: Setup crop diseases table and seed organic prevention data based on ICRISAT studies.
 */

exports.up = async (client) => {
  // Drop if exists to clean up any partial runs
  await client.query(`DROP TABLE IF EXISTS crop_diseases CASCADE`);

  // 1. Create crop_diseases table
  await client.query(`
    CREATE TABLE IF NOT EXISTS crop_diseases (
      id SERIAL PRIMARY KEY,
      crop_id INTEGER REFERENCES crops(id) ON DELETE CASCADE,
      name VARCHAR(150) NOT NULL,
      name_marathi VARCHAR(150) NOT NULL,
      stage VARCHAR(100) NOT NULL,
      stage_marathi VARCHAR(100) NOT NULL,
      symptoms TEXT NOT NULL,
      symptoms_marathi TEXT NOT NULL,
      organic_prevention TEXT NOT NULL,
      organic_prevention_marathi TEXT NOT NULL,
      severity VARCHAR(20) DEFAULT 'Medium',
      created_at TIMESTAMPTZ DEFAULT NOW()
    )
  `);

  // 2. Fetch crop IDs
  const cropsResult = await client.query('SELECT id, name FROM crops');
  const cropMap = {};
  cropsResult.rows.forEach(row => {
    cropMap[row.name.toLowerCase()] = row.id;
  });

  const insertQuery = `
    INSERT INTO crop_diseases (
      crop_id, name, name_marathi, stage, stage_marathi, symptoms, symptoms_marathi, organic_prevention, organic_prevention_marathi, severity
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)
  `;

  // --- ONION DISEASES ---
  const onionId = cropMap['onion'];
  if (onionId) {
    const onionDiseases = [
      [
        onionId,
        'Purple Blotch (Alternaria porri)',
        'जांभळा करपा (पर्पल ब्लॉच)',
        'Vegetative & Bulb Development (30-80 Days)',
        'शाकीय वाढ आणि कांदा धरण्याची अवस्था (३०-८० दिवस)',
        'Small, water-soaked lesions on leaves and seed stalks that quickly turn purple. Triggered by high humidity (>80%) and warm temperatures (25-30°C). Causes leaves to dry up and reduces bulb yield significantly.',
        'पानांवर आणि बियांच्या दांड्यावर पाण्यासारखे डाग पडतात, जे नंतर जांभळे होतात. ८०% पेक्षा जास्त आर्द्रता आणि २५-३०°C तापमानात हा रोग वेगाने पसरतो. यामुळे पाने सुकतात आणि कांद्याचे उत्पादन घटते.',
        '1. Dip seedlings in Trichoderma viride (10g/L water) for 15 mins before transplanting.\n2. Spray Neem Seed Kernel Extract (NSKE 5%) or Dashparni Ark @ 5ml/L water at first appearance.\n3. Implement crop rotation with non-allium crops for 2-3 years.\n4. Apply wooden ash on soil to build potassium immunity.',
        '१. पुनर्लागवडीपूर्वी रोपे ट्रायकोडर्मा व्हिरिडी (१० ग्रॅम/लिटर पाणी) च्या द्रावणात १५ मिनिटे बुडवावीत.\n२. रोग दिसू लागताच ५% निंबोळी अर्क किंवा दशपर्णी अर्क ५ मिली/लिटर पाण्यात मिसळून फवारावा.\n३. कांदा पिकाऐवजी इतर पिकांची २-३ वर्षे फेरपालट करावी.\n४. पोटॅशियमची प्रतिकारशक्ती वाढवण्यासाठी जमिनीवर लाकडाची राख टाकावी.',
        'High'
      ],
      [
        onionId,
        'Downy Mildew (Peronospora destructor)',
        'केवडा (डाउनी मिल्ड्यू)',
        'Early Vegetative Stage (20-50 Days)',
        'सुरुवातीची शाकीय वाढ (२०-५० दिवस)',
        'Purplish-white downy growth on leaf surfaces, followed by pale green or yellow discoloration. Flourishes in cool, damp conditions with heavy morning dew. Leads to leaf collapse.',
        'पानांच्या पृष्ठभागावर जांभळट-पांढरी बुरशी वाढते आणि पाने पिवळी पडतात. थंड, दमट वातावरण आणि सकाळच्या दवबिंदूंमुळे हा रोग वाढतो. यामुळे पाने कोलमडून पडतात.',
        '1. Ensure proper row spacing (15cm x 10cm) to allow air circulation.\n2. Spray Pseudomonas fluorescens @ 10g/L or copper-based organic formulations organically.\n3. Avoid overhead sprinkler irrigation during high humidity periods.\n4. Remove and destroy infected crop residues after harvest.',
        '१. हवेच्या हालचालीसाठी रोपांमध्ये योग्य अंतर (१५ सेमी x १० सेमी) ठेवावे.\n२. सेंद्रिय स्वरूपात सुडोमोनास फ्लोरेसेन्स १० ग्रॅम/लिटर किंवा तांब्रयुक्त सेंद्रिय औषधांची फवारणी करावी.\n३. हवेत आर्द्रता जास्त असताना तुषार सिंचन (स्प्रिंकलर) वापरणे टाळावे.\n४. काढणीनंतर बाधित पिकाचे अवशेष शेतातून काढून नष्ट करावेत.',
        'High'
      ],
      [
        onionId,
        'Damping-off & Basal Rot (Fusarium oxysporum)',
        'मर आणि सड रोग (बेसल रॉट)',
        'Seedling & Nursery Stage (0-30 Days)',
        'रोपवाटिका आणि सुरुवातीची अवस्था (०-३० दिवस)',
        'Soil-borne fungal attack causing seedlings to rot at the soil line and collapse. Triggered by waterlogging, poorly drained soils, and high soil temperatures. Bulbs start rotting from the roots.',
        'मातीतील बुरशीमुळे रोपे जमिनीलगत कुजतात आणि कोलमडतात. पाणी साचून राहणे, पाण्याचा निचरा न होणारी माती आणि वाढत्या तापमानामुळे हा रोग होतो. कांदे मुळांपासून कुजण्यास सुरुवात होते.',
        '1. Perform soil solarization of nursery beds during summer.\n2. Apply Trichoderma harzianum mixed with organic Farm Yard Manure (FYM) @ 5kg/acre to the soil before sowing.\n3. Ensure raised bed nursery for perfect drainage.\n4. Treat seeds with Trichoderma (5g/kg seed).',
        '१. उन्हाळ्यात रोपवाटिकेच्या जमिनीचे सोलारायझेशन (तपविणे) करावे.\n२. पेरणीपूर्वी ट्रायकोडर्मा हरझियानम शेणखतात (५ किलो/एकर) मिसळून जमिनीत टाकावे.\n३. पाण्याचा उत्तम निचरा होण्यासाठी गादीवाफ्यावर (Raised Bed) रोपवाटिका तयार करावी.\n४. बियाण्यास ट्रायकोडर्माची (५ ग्रॅम/किलो बियाणे) बीजप्रक्रिया करावी.',
        'High'
      ],
      [
        onionId,
        'Onion Thrips (Thrips tabaci)',
        'फुलकिडे (थ्रीप्स)',
        'Bulb Development & Sizing (50-100 Days)',
        'कांदा फुगवण आणि विकास (५०-१०० दिवस)',
        'Tiny insects suck plant sap, leading to silver-white streaks or patches on leaves. Triggered by hot, dry weather conditions. Badly infested leaves curl and dry up.',
        'बारीक कीटक पानांतील रस शोषून घेतात, ज्यामुळे पानांवर चकाकणारे पांढरे चट्टे पडतात. कोरड्या आणि उष्ण हवामानात हा प्रादुर्भाव वेगाने वाढतो. जास्त प्रादुर्भाव झाल्यास पाने पिळवटून सुकतात.',
        '1. Plant 2 rows of barrier crops like Maize or Sorghum around the field perimeter.\n2. Install blue sticky traps @ 20-30 traps per acre to capture adult thrips.\n3. Spray Dashparni Ark or garlic-chilli extract @ 5ml/L of water with natural soap adhesive.\n4. Maintain adequate field moisture to discourage thrips multiplying in dry soils.',
        '१. शेताच्या चहूबाजूंनी मका किंवा ज्वारीसारख्या पिकांच्या २ ओळी लावाव्यात.\n२. प्रौढ थ्रीप्स पकडण्यासाठी प्रति एकर २०-३० निळे चिकट सापळे लावावेत.\n३. नैसर्गिक साबणाच्या चिकट द्रावणासह दशपर्णी अर्क किंवा लसूण-मिरची अर्क ५ मिली/लिटर पाण्यात मिसळून फवारावा.\n४. कोरड्या मातीत थ्रीप्सची वाढ रोखण्यासाठी जमिनीत योग्य ओलावा ठेवावा.',
        'Medium'
      ]
    ];

    for (const d of onionDiseases) {
      await client.query(insertQuery, d);
    }
  }

  // --- TOMATO DISEASES ---
  const tomatoId = cropMap['tomato'];
  if (tomatoId) {
    const tomatoDiseases = [
      [
        tomatoId,
        'Early Blight (Alternaria solani)',
        'लवकर येणारा करपा (अर्ली ब्लाइट)',
        'Vegetative to Flowering Stage (25-60 Days)',
        'शाकीय वाढ ते फुलोरा अवस्था (२५-६० दिवस)',
        'Concentric brown rings resembling target boards on older leaves. Warm weather combined with frequent rain or dew triggers fungal sporulation.',
        'पानांवर वर्तुळाकार तपकिरी रंगाचे डाग पडतात, जे निशाण्यासारखे दिसतात. उष्ण हवामान आणि सततचा पाऊस किंवा दव यामुळे हा बुरशीजन्य आजार पसरतो.',
        '1. Prune lower leaves up to 1 foot above the ground to avoid soil splashing.\n2. Apply thick straw mulch to create a barrier between soil fungi and foliage.\n3. Spray Trichoderma viride or Pseudomonas @ 10g/L water.\n4. Avoid overhead sprinkler watering.',
        '१. मातीचे उडणारे पाणी पानांवर पडू नये म्हणून जमिनीपासून १ फुटापर्यंतची खालची पाने छाटावीत.\n२. जमिनीतील बुरशी पानांपर्यंत पोहोचू नये म्हणून पेंढ्याचे जाड आच्छादन (मल्चिंग) करावे.\n३. ट्रायकोडर्मा व्हिरिडी किंवा सुडोमोनास १० ग्रॅम/लिटर पाण्यात मिसळून फवारणी करावी.\n४. स्प्रिंकलरने पाणी देणे टाळावे.',
        'Medium'
      ],
      [
        tomatoId,
        'Tomato Leaf Curl Virus (TLCV)',
        'पर्णगुच्छ किंवा चुरडा-मुरडा (लीफ कर्ल)',
        'All growth stages (20-120 Days)',
        'सर्व अवस्था (२०-१२० दिवस)',
        'Severe stunting of plants, yellowing and upward curling of leaf margins. Transmitted by Whitefly vector. Triggered by hot, dry dry spells.',
        'झाडांची वाढ खुंटते, पाने पिवळी पडतात आणि कडा वरच्या बाजूला वळतात (चुरडतात). हा विषाणू पांढऱ्या माशीद्वारे पसरतो. उष्ण आणि कोरड्या हवामानात हा रोग वेगाने वाढतो.',
        '1. Install yellow sticky traps @ 25 traps per acre.\n2. Spray Neem Oil (10,000 PPM) @ 3ml/L or fish oil rosin soap to control whiteflies.\n3. Remove and burn heavily infected plants immediately.\n4. Grow border crops of tall sorghum or maize.',
        '१. पांढरी माशी नियंत्रित करण्यासाठी एकरी २५ पिवळे चिकट सापळे लावावेत.\n२. पांढऱ्या माशीच्या नियंत्रणासाठी निंबोळी तेल (१०,००० PPM) ३ मिली/लिटर किंवा फिश ऑईल रोझिन सोप फवारावा.\n३. जास्त बाधित झाडे तात्काळ उपटून टाकून नष्ट करावीत.\n४. शेताभोवती ज्वारी किंवा मक्यासारखी उंच पिके लावावीत.',
        'High'
      ]
    ];

    for (const d of tomatoDiseases) {
      await client.query(insertQuery, d);
    }
  }

  // --- SUGARCANE DISEASES ---
  const sugarcaneId = cropMap['sugarcane'];
  if (sugarcaneId) {
    const sugarcaneDiseases = [
      [
        sugarcaneId,
        'Red Rot (Colletotrichum falcatum)',
        'लाल कुज (रेड रॉट)',
        'Grand Growth Stage (120-240 Days)',
        'जोमदार वाढीची अवस्था (१२०-२४० दिवस)',
        'Internal stalk tissues turn red with white cross bands. Leaves wither and dry from the tips. Caused by waterlogging and infected setts planting.',
        'उसाच्या कांड्या आतून लाल रंगाच्या होतात आणि त्यामध्ये पांढरे पट्टे दिसतात. पाने शेंड्यापासून वाळू लागतात. पाणी साचून राहणे आणि बाधित बेणे लागवडीमुळे हा रोग होतो.',
        '1. Select healthy setts from certified disease-free nurseries.\n2. Treat seed setts with warm water or Trichoderma solution before planting.\n3. Provide excellent drainage channels to avoid standing water.\n4. Burn crop residues after harvesting.',
        '१. निरोगी आणि प्रमाणित बेणे मळ्यातूनच उसाची निवड करावी.\n२. लागवडीपूर्वी बेण्यास कोमट पाण्याची किंवा ट्रायकोडर्मा द्रावणाची प्रक्रिया करावी.\n३. शेतात पाणी साचू नये म्हणून पाण्याचा उत्तम निचरा करावा.\n४. काढणीनंतर उसाचे अवशेष शेतातच जाळून नष्ट करावेत.',
        'High'
      ],
      [
        sugarcaneId,
        'Sugarcane Smut (Sporisorium scitamineum)',
        'चाबूक काणी (स्मट)',
        'Tillering & Early Growth (60-150 Days)',
        'फुटवा आणि सुरुवातीची वाढ (६०-१५० दिवस)',
        'A long, black whip-like dusty structure emerges from the shoot apex. Spores are easily carried by summer wind. Greatly stunts crop growth.',
        'उसाच्या शेंड्यातून काळ्या रंगाचा लांब चाबकासारखा भाग बाहेर येतो ज्यावर काळी पूड असते. उन्हाळ्यातील वाऱ्यामुळे या रोगाचे बीजाणू वेगाने पसरतात. यामुळे उसाची वाढ पूर्णपणे खुंटते.',
        '1. Inspect field regularly and carefully bag infected whips before cutting to prevent spore release.\n2. Do not use ratoon crop if smut is noticed in main crop.\n3. Grow smut-resistant varieties (e.g. Co 86032, CoM 0265).\n4. Deep summer ploughing.',
        '१. शेताची नियमित पाहणी करावी, काणी आलेला भाग कापण्यापूर्वी प्लास्टिक पिशवीत झाकावा जेणेकरून काळी पूड हवेत पसरणार नाही.\n२. मुख्य पिकात हा रोग आढळल्यास खोडवा पीक घेणे टाळावे.\n३. रोगप्रतिकारक वाणांची (उदा. को ८६०३२, कोएम ०२६५) निवड करावी.\n४. उन्हाळ्यात जमिनीची खोल नांगरट करावी.',
        'High'
      ]
    ];

    for (const d of sugarcaneDiseases) {
      await client.query(insertQuery, d);
    }
  }

  // --- GENERIC DISEASES FOR OTHER CROPS ---
  const allOtherCrops = cropsResult.rows.filter(row => 
    !['onion', 'tomato', 'sugarcane'].includes(row.name.toLowerCase())
  );

  for (const c of allOtherCrops) {
    const genericDiseases = [
      [
        c.id,
        'Powdery Mildew (Erysiphe / Leveillula)',
        'भुरी रोग (पावडरी मिल्ड्यू)',
        'Flowering & Fruit Development Stage',
        'फुलोरा आणि फळ विकास अवस्था',
        'White, powdery fungal patches on the upper leaf surface, causing yellowing and premature leaf fall. Prefers dry weather with humid microclimate.',
        'आता पानांच्या वरच्या बाजूला पांढरी पिठासारखी बुरशी पसरते, ज्यामुळे पाने पिवळी पडून गळतात. कोरडे हवामान आणि झाडांमधील आर्द्रतेमुळे हा रोग वाढतो.',
        '1. Spray baking soda (Sodium bicarbonate @ 5g/L) mixed with liquid soap as an organic fungicide.\n2. Spray milk diluted in water (1:10 ratio) under bright sunlight.\n3. Ensure proper spacing to maximize solar penetration inside canopy.\n4. Spray wettable sulphur organically if severity is low.',
        '१. सेंद्रिय बुरशीनाशक म्हणून खाण्याचा सोडा (५ ग्रॅम/लिटर) आणि द्रव साबण यांचे मिश्रण करून फवारावे.\n२. कडक उन्हात दूध आणि पाण्याचे (१:१० प्रमाणात) मिश्रण फवारावे.\n३. सूर्यप्रकाश झाडांच्या आतपर्यंत पोहोचण्यासाठी योग्य अंतर ठेवावे.\n४. प्रादुर्भाव कमी असल्यास सेंद्रिय गंधकाची फवारणी करावी.',
        'Medium'
      ],
      [
        c.id,
        'Root Rot & Wilt (Pythium / Rhizoctonia)',
        'मूळकुज आणि मर रोग (रूट रॉट)',
        'Early Establishment & Growth Stage',
        'सुरुवातीची वाढ आणि मुळांचा विकास',
        'Decay of fibrous roots, plant wilting even in moist soil, leaf yellowing. Triggered by heavy soils with poor drainage and excessive watering.',
        'तंतुमय मुळे कुजतात, जमिनिवर ओलावा असतानाही झाड सुकते आणि पाने पिवळी पडतात. पाण्याचा योग्य निचरा न होणारी माती आणि जास्त पाण्यामुळे हा रोग होतो.',
        '1. Apply Trichoderma mixed with organic manure near the root zone.\n2. Drench with copper hydroxide equivalent organic formulation or Cow Urine formulation.\n3. Regulate watering and prevent waterlogging around plant stems.\n4. Implement crop rotation.',
        '१. मुळांच्या भोवती ट्रायकोडर्मा सेंद्रिय खतामध्ये मिसळून टाकावा.\n२. सेंद्रिय पद्धतीने तांब्रयुक्त द्रावण किंवा गोमूत्र अर्काची आळवणी (ड्रेंचिंग) करावी.\n३. पाणी देण्याचे प्रमाण नियंत्रित करावे आणि खोडाजवळ पाणी साचू देऊ नये.\n४. पिकांची फेरपालट करावी.',
        'High'
      ]
    ];

    for (const d of genericDiseases) {
      await client.query(insertQuery, d);
    }
  }
};

exports.down = async (client) => {
  await client.query('DROP TABLE IF EXISTS crop_diseases');
};
