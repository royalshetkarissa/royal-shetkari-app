const logger = require('../utils/logger');

/**
 * Global Error Handler Middleware
 */
const errorMiddleware = (err, req, res, next) => {
  // Handle Multer upload errors
  if (err.name === 'MulterError') {
    err.statusCode = 400;
    err.status = 'fail';
    err.isOperational = true;
    if (err.code === 'LIMIT_FILE_SIZE') {
      err.message = 'File size limit exceeded. Maximum file size allowed is 8MB.';
    } else if (err.code === 'LIMIT_FILE_COUNT') {
      err.message = 'Too many files uploaded. Maximum files allowed per request is 5.';
    } else {
      err.message = `Upload error: ${err.message}`;
    }
  }

  err.statusCode = err.statusCode || 500;
  err.status = err.status || 'error';

  // Log the error with request ID
  logger.error({
    requestId: req.id,
    message: err.message,
    stack: err.stack,
    url: req.originalUrl,
    method: req.method,
  });

  if (process.env.NODE_ENV === 'development') {
    res.status(err.statusCode).json({
      status: err.status,
      requestId: req.id,
      message: err.message,
      stack: err.stack,
      error: err,
    });
  } else {
    // Production: Hide sensitive details
    // Operational, trusted error: send message to client
    if (err.isOperational) {
      res.status(err.statusCode).json({
        status: err.status,
        requestId: req.id,
        message: err.message,
      });
    } else {
      // Programming or other unknown error: don't leak error details
      res.status(500).json({
        status: 'error',
        requestId: req.id,
        message: 'Something went very wrong! Please contact support with the Request ID.',
      });
    }
  }
};

module.exports = errorMiddleware;
