const fs = require('fs').promises;
const path = require('path');
const { S3Client, PutObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const logger = require('./logger');

const isB2Configured = process.env.B2_ENDPOINT && process.env.B2_ACCESS_KEY_ID && process.env.B2_SECRET_ACCESS_KEY && process.env.B2_BUCKET_NAME;

const s3Client = isB2Configured
  ? new S3Client({
      endpoint: process.env.B2_ENDPOINT,
      region: process.env.B2_REGION || 'us-east-1', // B2 region is often auto-detected or specified in endpoint
      credentials: {
        accessKeyId: process.env.B2_ACCESS_KEY_ID,
        secretAccessKey: process.env.B2_SECRET_ACCESS_KEY,
      },
    })
  : null;

/**
 * Uploads a local file to B2 bucket and returns a presigned URL or public URL.
 * Falls back to local URL if B2 is not configured.
 * 
 * @param {Object} file Multer file object
 * @param {string} prefix Folder prefix
 * @returns {Promise<string>} Image URL
 */
async function uploadToB2IfNeeded(file, prefix = 'general') {
  if (!file) return null;

  if (!isB2Configured) {
    logger.warn('B2 is not configured, falling back to local storage.');
    return `/uploads/${file.filename}`;
  }

  try {
    const fileBuffer = await fs.readFile(file.path);
    const key = `${prefix}/${file.filename}`;

    const command = new PutObjectCommand({
      Bucket: process.env.B2_BUCKET_NAME,
      Key: key,
      Body: fileBuffer,
      ContentType: file.mimetype,
    });

    await s3Client.send(command);
    logger.info(`Successfully uploaded ${file.filename} to B2`);

    // We can clean up the local file after successful upload
    await fs.unlink(file.path).catch(e => logger.error(`Failed to clean up local file ${file.path}: ${e.message}`));

    // If bucket is private, generate a presigned URL (valid for 7 days)
    // If public, you can just return the constructed public URL.
    // Assuming presigned URLs for better security/portability:
    const urlCommand = new PutObjectCommand({ Bucket: process.env.B2_BUCKET_NAME, Key: key });
    // Wait, getSignedUrl requires GetObjectCommand to read the file, not PutObjectCommand.
    // Actually, for public access or standard usage, let's just generate a GetObject presigned URL.
    const { GetObjectCommand } = require('@aws-sdk/client-s3');
    const getCommand = new GetObjectCommand({ Bucket: process.env.B2_BUCKET_NAME, Key: key });
    
    // Default to 7 days expiry
    const url = await getSignedUrl(s3Client, getCommand, { expiresIn: 7 * 24 * 3600 });
    return url;

  } catch (error) {
    logger.error(`Error uploading to B2: ${error.message}`);
    // Fallback to local if B2 upload fails
    return `/uploads/${file.filename}`;
  }
}

module.exports = {
  uploadToB2IfNeeded,
  s3Client,
};
