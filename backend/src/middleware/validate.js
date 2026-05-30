const AppError = require('../utils/AppError');

/**
 * Middleware to validate request body using a Zod schema.
 * @param {z.ZodObject} schema - The Zod schema to validate against.
 */
const validate = (schema) => (req, res, next) => {
  try {
    req.body = schema.parse(req.body);
    next();
  } catch (error) {
    const issues = error.issues || error.errors;
    if (issues && Array.isArray(issues)) {
      const message = issues.map((err) => `${err.path.join('.')}: ${err.message}`).join(', ');
      return next(new AppError(message, 400));
    }
    next(error);
  }
};

module.exports = validate;
