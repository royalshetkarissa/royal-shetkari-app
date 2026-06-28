const { connection: redis } = require('./src/config/redis');

async function verify() {
  // Wait a moment for connection
  await new Promise(resolve => setTimeout(resolve, 500));
  
  console.log('Connected to Redis...');
  const keys = await redis.keys('rl:*');
  console.log('Rate Limit Keys Found:', keys.length > 0 ? keys : 'None');
  
  // Clean up test keys if needed
  if (keys.length > 0) {
    console.log('Details for first key:', keys[0]);
    const ttl = await redis.ttl(keys[0]);
    console.log(`TTL for ${keys[0]}: ${ttl}s`);
  }
  
  await redis.quit();
}

verify().catch(console.error);
