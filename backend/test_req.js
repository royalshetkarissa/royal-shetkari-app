const request = require('supertest');
const app = require('./src/app');

async function test() {
  const res = await request(app)
    .post('/api/v1/register')
    .send({ mobile: '123' });
  
  console.log(JSON.stringify(res.body, null, 2));
  process.exit(0);
}

test();
