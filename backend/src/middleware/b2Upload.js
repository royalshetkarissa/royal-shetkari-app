const multer = require('multer');
const path = require('path');
const AppError = require('../utils/AppError');

const storage = multer.memoryStorage();

// Accepted extensions and their canonical MIME types
const allowedExtensions = {
  '.jpg':  'image/jpeg',
  '.jpeg': 'image/jpeg',
  '.png':  'image/png',
  '.webp': 'image/webp',
  '.pdf':  'application/pdf',
};

// Valid MIME types
const allowedMimeTypes = new Set(Object.values(allowedExtensions));

const dangerousExtensions = new Set([
  '.exe', '.bat', '.sh', '.js', '.php', '.apk', '.bin', '.cmd', '.com', '.msi',
]);

const fileFilter = (req, file, cb) => {
  const ext = path.extname(file.originalname).toLowerCase();

  // 1. Block explicitly dangerous extensions regardless of MIME
  if (dangerousExtensions.has(ext)) {
    return cb(new AppError('Dangerous or unsupported file extension rejected.', 400), false);
  }

  // 2. Normalise the MIME type:
  //    Some mobile clients send 'application/octet-stream' for images.
  //    In that case, fall back to the extension-based lookup.
  let effectiveMime = file.mimetype;
  if (
    !allowedMimeTypes.has(effectiveMime) &&
    allowedExtensions[ext]
  ) {
    // Trust the extension — the client just didn't set Content-Type correctly
    effectiveMime = allowedExtensions[ext];
    file.mimetype = effectiveMime; // normalise so downstream code is consistent
  }

  // 3. Final MIME check
  if (!allowedMimeTypes.has(effectiveMime)) {
    return cb(
      new AppError(
        `Invalid file type (${file.mimetype}). Only JPEG, PNG, WEBP images and PDF documents are allowed.`,
        400
      ),
      false
    );
  }

  // 4. Extension must match one of our allowed extensions
  if (!allowedExtensions[ext]) {
    return cb(new AppError('Unsupported file extension.', 400), false);
  }

  cb(null, true);
};

const b2Upload = multer({
  storage: storage,
  limits: {
    fileSize: 8 * 1024 * 1024, // 8 MB
    files: 11,                  // 1 profile + 10 gallery
  },
  fileFilter: fileFilter,
});

module.exports = b2Upload;
