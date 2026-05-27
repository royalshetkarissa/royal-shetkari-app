const logger = require('../utils/logger');

/**
 * Global Error Handler Middleware
 */
const errorMiddleware = (err, req, res, next) => {
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
