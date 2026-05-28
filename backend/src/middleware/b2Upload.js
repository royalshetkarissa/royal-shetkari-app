const multer = require('multer');
const path = require('path');
const AppError = require('../utils/AppError');

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
  const ext = path.extname(file.originalname).toLowerCase();
  if (dangerousExtensions.includes(ext) || !ext) {
    return cb(new AppError('Dangerous or unsupported file extension rejected.', 400), false);
  }

  cb(null, true);
};

const b2Upload = multer({
  storage: storage,
  limits: {
    fileSize: 8 * 1024 * 1024, // 8 MB
    files: 10,
  },
  fileFilter: fileFilter,
});

module.exports = b2Upload;
