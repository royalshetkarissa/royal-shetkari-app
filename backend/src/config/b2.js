const { S3Client } = require('@aws-sdk/client-s3');

const endpoint = process.env.B2_ENDPOINT || 'https://s3.eu-central-003.backblazeb2.com';

const s3Client = new S3Client({
  endpoint,
  credentials: {
    accessKeyId: process.env.B2_KEY_ID || 'YOUR_KEY_ID',
    secretAccessKey: process.env.B2_APP_KEY || 'YOUR_APP_KEY',
  },
  region: process.env.B2_REGION || 'eu-central-003',
  forcePathStyle: true, // Forces path-style routing to work correctly with Railway MinIO and custom S3 endpoints
});

module.exports = s3Client;
