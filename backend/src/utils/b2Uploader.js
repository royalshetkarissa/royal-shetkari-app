const { PutObjectCommand } = require('@aws-sdk/client-s3');
const path = require('path');
const s3Client = require('../config/b2');

/**
 * Uploads a file buffer (from Multer memoryStorage) to Backblaze B2.
 * Returns the path `/api/image/<fileKey>` which resolves through express GET /api/image/*
 * 
 * @param {Express.Multer.File} file 
 * @returns {Promise<string|null>}
 */
async function uploadToB2(file) {
  if (!file) return null;
  const extension = path.extname(file.originalname) || '.jpg';
  const fileKey = `${Date.now()}-${Math.random().toString(36).substring(2, 15)}${extension}`;

  const uploadCommand = new PutObjectCommand({
    Bucket: process.env.B2_BUCKET || 'rsitapp-images',
    Key: fileKey,
    Body: file.buffer,
    ContentType: file.mimetype,
  });

  await s3Client.send(uploadCommand);
  return `/api/image/${fileKey}`;
}

module.exports = { uploadToB2 };
