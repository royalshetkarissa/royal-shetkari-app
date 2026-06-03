const fs = require('fs').promises;
const path = require('path');
const { PutObjectCommand } = require('@aws-sdk/client-s3');
const s3Client = require('../config/b2');

/**
 * Uploads a local file (from multer diskStorage) to Backblaze B2 if configured.
 * Otherwise, falls back to the local uploads path.
 * Automatically deletes the local file if uploaded to B2.
 * 
 * @param {Object} file Multer file object
 * @param {string} prefix Folder prefix in B2 (e.g. 'posts', 'profiles', 'shops')
 * @returns {Promise<string>} Image URL (B2 proxy url or local uploads url)
 */
async function uploadToB2IfNeeded(file, prefix = 'general') {
  if (!file) return null;

  try {
    if (process.env.B2_KEY_ID && process.env.B2_KEY_ID !== 'YOUR_KEY_ID') {
      const fileKey = `${prefix}/${Date.now()}-${Math.random().toString(36).substring(2, 10)}-${file.filename}`;
      const fileBuffer = await fs.readFile(file.path);

      const uploadCommand = new PutObjectCommand({
        Bucket: process.env.B2_BUCKET || 'rsitapp-images',
        Key: fileKey,
        Body: fileBuffer,
        ContentType: file.mimetype,
      });

      await s3Client.send(uploadCommand);

      // Delete local file to free up space
      await fs.unlink(file.path);

      // Return the secure proxy image URL
      return `/api/image/${fileKey}`;
    }
  } catch (err) {
    console.error(`B2 Upload failed for file ${file.filename}, falling back to local:`, err);
  }

  // Fallback to local uploads path
  return `/uploads/${file.filename}`;
}

module.exports = {
  uploadToB2IfNeeded,
};
