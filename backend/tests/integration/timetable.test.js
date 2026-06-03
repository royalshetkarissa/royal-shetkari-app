const request = require('supertest');
const app = require('../../src/app');
const pool = require('../../src/config/db');
const jwtHelper = require('../../src/utils/jwtHelper');

describe('Timetable Crops & Diseases Integration Tests', () => {
  let testUser;
  let token;
  let testCropId;

  beforeAll(async () => {
    // Retrieve first seeded crop
    const cropResult = await pool.query('SELECT * FROM crops LIMIT 1');
    if (cropResult.rows.length > 0) {
      testCropId = cropResult.rows[0].id;
    } else {
      const dummyCrop = await pool.query(
        `INSERT INTO crops (name, marathi_name, category) 
         VALUES ('Onion', 'कांदा', 'vegetables') RETURNING *`
      );
      testCropId = dummyCrop.rows[0].id;
    }

    // Ensure there is at least one disease seeded for this crop id
    const diseaseResult = await pool.query('SELECT * FROM crop_diseases WHERE crop_id = $1 LIMIT 1', [testCropId]);
    if (diseaseResult.rows.length === 0) {
      await pool.query(
        `INSERT INTO crop_diseases (crop_id, name, name_marathi, stage, stage_marathi, symptoms, symptoms_marathi, organic_prevention, organic_prevention_marathi)
         VALUES ($1, 'Test Disease', 'चाचणी रोग', 'Vegetative', 'शाकीय', 'Test symptoms', 'चाचणी लक्षणे', 'Test prevention', 'चाचणी प्रतिबंध')`,
        [testCropId]
      );
    }

    // Create a test user
    const mobile = '9900' + Math.floor(100000 + Math.random() * 900000);
    const userRes = await pool.query(
      `INSERT INTO users (full_name, mobile, password, village) 
       VALUES ('Timetable Test User', $1, 'hashedpassword', 'Test Village') RETURNING *`,
      [mobile]
    );
    testUser = userRes.rows[0];

    token = jwtHelper.signAccessToken({
      id: testUser.id,
      mobile: testUser.mobile,
      name: testUser.full_name,
      isAdmin: testUser.is_admin,
      role: testUser.role,
      permissions: testUser.permissions,
    });
  });

  afterAll(async () => {
    if (testUser) {
      await pool.query('DELETE FROM users WHERE id = $1', [testUser.id]);
    }
  });

  it('should fetch diseases for a crop successfully', async () => {
    const res = await request(app)
      .get(`/api/v1/timetable/crops/${testCropId}/diseases`)
      .set('Authorization', `Bearer ${token}`);

    expect(res.statusCode).toEqual(200);
    expect(res.body.success).toBe(true);
    expect(res.body.diseases).toBeInstanceOf(Array);
    expect(res.body.diseases.length).toBeGreaterThan(0);
    expect(res.body.diseases[0]).toHaveProperty('name');
    expect(res.body.diseases[0]).toHaveProperty('organic_prevention');
  });

  it('should fail to fetch diseases if unauthorized', async () => {
    const res = await request(app)
      .get(`/api/v1/timetable/crops/${testCropId}/diseases`);

    expect(res.statusCode).toEqual(401);
  });

  it('should create a crop journey and complete tasks awarding coins', async () => {
    // 1. Start journey
    const startRes = await request(app)
      .post('/api/v1/timetable/start-journey')
      .set('Authorization', `Bearer ${token}`)
      .send({
        cropId: testCropId,
        plantingDate: new Date().toISOString().split('T')[0],
      });

    expect(startRes.statusCode).toEqual(201);
    expect(startRes.body.success).toBe(true);
    expect(startRes.body.journey).toHaveProperty('id');
    const journeyId = startRes.body.journey.id;

    // 2. Fetch journeys and tasks
    const listRes = await request(app)
      .get('/api/v1/timetable/my-journeys')
      .set('Authorization', `Bearer ${token}`);

    expect(listRes.statusCode).toEqual(200);
    expect(listRes.body.success).toBe(true);
    const journey = listRes.body.journeys.find((j) => j.id === journeyId);
    expect(journey).toBeDefined();
    expect(journey.tasks).toBeInstanceOf(Array);
    expect(journey.tasks.length).toBeGreaterThan(0);
    const taskId = journey.tasks[0].id;

    // 3. Verify user's initial coins is 0
    const userBeforeRes = await pool.query('SELECT coins FROM users WHERE id = $1', [testUser.id]);
    expect(userBeforeRes.rows[0].coins).toEqual(0);

    // 4. Complete task
    const completeRes = await request(app)
      .patch(`/api/v1/timetable/tasks/${taskId}/complete`)
      .set('Authorization', `Bearer ${token}`);

    expect(completeRes.statusCode).toEqual(200);
    expect(completeRes.body.success).toBe(true);
    expect(completeRes.body.message).toContain('completed');

    // 5. Verify user's coins is now 1
    const userAfterRes = await pool.query('SELECT coins FROM users WHERE id = $1', [testUser.id]);
    expect(userAfterRes.rows[0].coins).toEqual(1);

    // 6. Complete task again should fail
    const completeAgainRes = await request(app)
      .patch(`/api/v1/timetable/tasks/${taskId}/complete`)
      .set('Authorization', `Bearer ${token}`);

    expect(completeAgainRes.statusCode).toEqual(400); // throws operational error
    expect(completeAgainRes.body.message).toContain('already completed');

    // Clean up journey & tasks
    await pool.query('DELETE FROM user_crop_journeys WHERE id = $1', [journeyId]);
  });

  it('should fetch daily tasks due today successfully', async () => {
    // 1. Create a template for today (day_offset = 0)
    const templateRes = await pool.query(
      `INSERT INTO crop_templates (crop_id, day_offset, task_name, task_marathi, organic_details)
       VALUES ($1, 0, 'Seed Planting Test', 'बियाणे पेरणे चाचणी', 'Test Organic Compost') RETURNING id`,
      [testCropId]
    );
    const templateId = templateRes.rows[0].id;

    // Get database's current date to align plantingDate and CURRENT_DATE timezone
    const dateRes = await pool.query("SELECT TO_CHAR(CURRENT_DATE, 'YYYY-MM-DD') as today");
    const dbToday = dateRes.rows[0].today;

    // 2. Start a crop journey today
    const startRes = await request(app)
      .post('/api/v1/timetable/start-journey')
      .set('Authorization', `Bearer ${token}`)
      .send({
        cropId: testCropId,
        plantingDate: dbToday,
      });
    const journeyId = startRes.body.journey.id;

    // 3. Fetch daily tasks in English
    const dailyTasksRes = await request(app)
      .get('/api/v1/timetable/daily-tasks')
      .set('Authorization', `Bearer ${token}`);

    expect(dailyTasksRes.statusCode).toEqual(200);
    expect(dailyTasksRes.body.success).toBe(true);
    expect(dailyTasksRes.body.tasks).toBeInstanceOf(Array);
    expect(dailyTasksRes.body.tasks.length).toBeGreaterThan(0);
    
    const cropGroup = dailyTasksRes.body.tasks.find(g => g.dayOffset === 0);
    expect(cropGroup).toBeDefined();
    expect(cropGroup.tasks[0].task_description).toEqual('Seed Planting Test');
    expect(cropGroup.tasks[0].organic_product).toEqual('Test Organic Compost');

    // 4. Fetch daily tasks in Marathi (Header)
    const dailyTasksResMr = await request(app)
      .get('/api/v1/timetable/daily-tasks')
      .set('Authorization', `Bearer ${token}`)
      .set('Accept-Language', 'mr');

    expect(dailyTasksResMr.statusCode).toEqual(200);
    const cropGroupMr = dailyTasksResMr.body.tasks.find(g => g.dayOffset === 0);
    expect(cropGroupMr).toBeDefined();
    expect(cropGroupMr.tasks[0].task_description).toEqual('बियाणे पेरणे चाचणी');

    // Clean up
    await pool.query('DELETE FROM user_crop_journeys WHERE id = $1', [journeyId]);
    await pool.query('DELETE FROM crop_templates WHERE id = $1', [templateId]);
  });
});
