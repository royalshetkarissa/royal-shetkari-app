const { z } = require('zod');

exports.createBookingSchema = z.object({
  booking_date: z.string().regex(/^\d{4}-\d{2}-\d{2}$/, 'Date must be in YYYY-MM-DD format'),
  booking_time: z.string().regex(/^\d{2}:\d{2}(:\d{2})?$/, 'Time must be in HH:mm format'),
  help_type: z.string().min(2, 'Help type is required'),
  mobile: z.string().min(10, 'Invalid mobile number'),
});
