const express = require('express');
const multer = require('multer');
const path = require('path');
const { PutObjectCommand, GetObjectCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const s3Client = require('../../config/b2');
const { verifyToken } = require('../../middleware/auth');
const pool = require('../../config/db');
const AppError = require('../../utils/AppError');

const router = express.Router();
const storage = multer.memoryStorage();

const allowedMimeTypes = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

const dangerousExtensions = [
  '.exe',
  '.bat',
  '.sh',
  '.js',
  '.php',
  '.apk',
  '.bin',
  '.cmd',
  '.com',
  '.msi',
];

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();

  // Fallback: if mimetype is generic, wrong, or missing, normalize/infer from extension
  if (!allowedMimeTypes.includes(file.mimetype) && ext) {
    const mimeMap = {
      '.jpg': 'image/jpeg',
      '.jpeg': 'image/jpeg',
      '.png': 'image/png',
      '.webp': 'image/webp',
      '.pdf': 'application/pdf',
    };
    if (mimeMap[ext]) {
      file.mimetype = mimeMap[ext];
    }
  }

  // 1. Verify MIME type
  if (!allowedMimeTypes.includes(file.mimetype)) {
    return cb(
      new AppError(
        'Invalid file type. Only JPEG, PNG, WEBP images and PDF documents are allowed.',
        400
      ),
      false
    );
  }

  // 2. Verify file extension to prevent bypasses/obfuscation
  if (dangerousExtensions.includes(ext) || !ext) {
    return cb(new AppError('Dangerous or unsupported file extension rejected.', 400), false);
  }

  cb(null, true);
};

const upload = multer({
  storage: storage,
  limits: {
    fileSize: 8 * 1024 * 1024, // 8 MB
    files: 5,
  },
  fileFilter: fileFilter,
});

// POST /upload - Uploads image to Backblaze B2 and saves record to PostgreSQL posts table
router.post('/upload', verifyToken, upload.single('image'), async (req, res, next) => {
  try {
    const file = req.file;
    if (!file) {
      return res.status(400).json({ error: 'No image file uploaded' });
    }

    const { caption } = req.body;

    // Generate unique key
    const extension = path.extname(file.originalname) || '.jpg';
    const fileKey = `${Date.now()}-${Math.random().toString(36).substring(2, 15)}${extension}`;

    // Upload to Backblaze B2
    const uploadCommand = new PutObjectCommand({
      Bucket: process.env.B2_BUCKET || 'rsitapp-images',
      Key: fileKey,
      Body: file.buffer,
      ContentType: file.mimetype,
    });

    await s3Client.send(uploadCommand);

    // Save record to PostgreSQL posts table
    // Storing in custom columns file_key, caption, and compatibility columns (title, description)
    const result = await pool.query(
      `INSERT INTO posts (user_id, file_key, caption, title, description, category, status, created_at)
       VALUES ($1, $2, $3, $4, $5, 'general', 'active', NOW()) RETURNING *`,
      [req.userId, fileKey, caption || '', caption || 'Upload', caption || 'Backblaze B2 Upload']
    );

    res.status(201).json({
      success: true,
      message: 'Image uploaded and post saved successfully',
      post: result.rows[0],
      fileKey,
    });
  } catch (error) {
    next(error);
  }
});

// GET /image/* - Generates a temporary getSignedUrl and redirects the request
router.get('/image/*', async (req, res, next) => {
  try {
    const key = req.params[0];
    const command = new GetObjectCommand({
      Bucket: process.env.B2_BUCKET || 'rsitapp-images',
      Key: key,
    });

    const signedUrl = await getSignedUrl(s3Client, command, { expiresIn: 3600 });

    // Redirect the browser/app to the signed url
    res.redirect(signedUrl);
  } catch (error) {
    next(error);
  }
});

module.exports = router;
