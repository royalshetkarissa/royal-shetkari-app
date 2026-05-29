const multer = require('multer');
const path = require('path');
const fs = require('fs');
const AppError = require('../utils/AppError');

const uploadDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadDir)) {
  fs.mkdirSync(uploadDir, { recursive: true });
}

const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    cb(null, uploadDir);
  },
  filename: (req, file, cb) => {
    const uniqueSuffix = Date.now() + '-' + Math.round(Math.random() * 1e9);
    // Sanitize filename: prevent path traversal and remove special chars
    const baseName = path.basename(file.originalname);
    const sanitizedName = baseName.replace(/[^a-zA-Z0-9.-]/g, '_');
    cb(null, uniqueSuffix + '-' + sanitizedName);
  },
});

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

module.exports = upload;
