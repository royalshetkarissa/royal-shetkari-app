const { S3Client } = require('@aws-sdk/client-s3');

const s3Client = new S3Client({
  endpoint: process.env.B2_ENDPOINT || 'https://s3.eu-central-003.backblazeb2.com',
  credentials: {
    accessKeyId: process.env.B2_KEY_ID || 'YOUR_KEY_ID',
    secretAccessKey: process.env.B2_APP_KEY || 'YOUR_APP_KEY',
  },
  region: 'eu-central-003',
  forcePathStyle: true,
});

module.exports = s3Client;
