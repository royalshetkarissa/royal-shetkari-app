const { z } = require('zod');

// Helpers to preprocess fields that can be sent as strings, numbers, or empty/null
const coerceToOptionalNumber = z.preprocess((val) => {
  if (val === '' || val === null || val === undefined || val === 'null' || val === 'undefined') {
    return null;
  }
  const num = Number(val);
  return isNaN(num) ? val : num;
}, z.number().optional().nullable());

const coerceToOptionalString = z.preprocess((val) => {
  if (val === '' || val === null || val === undefined || val === 'null' || val === 'undefined') {
    return null;
  }
  return String(val);
}, z.string().optional().nullable());

exports.createPostSchema = z
  .object({
    category: z.string().min(1, 'Category is required'),
    title: z.string().min(1, 'Title is required'),
    description: z.string().min(1, 'Description is required'),
    price: coerceToOptionalNumber,
    location: z.string().min(1, 'Location is required'),
    contact_number: z.string().min(10, 'Invalid contact number').optional(),
    contact_mobile: z.string().min(10, 'Invalid contact number').optional(),
    latitude: coerceToOptionalNumber,
    longitude: coerceToOptionalNumber,
    animal_type: coerceToOptionalString,
    lactation: coerceToOptionalString,
    milk_per_day: coerceToOptionalNumber,
  })
  .refine((data) => data.contact_number || data.contact_mobile, {
    message: 'Contact number is required',
    path: ['contact_number'],
  });

exports.updatePostSchema = z.object({
  category: z.string().optional(),
  title: z.string().min(1).optional(),
  description: z.string().min(1).optional(),
  price: coerceToOptionalNumber,
  location: z.string().optional(),
  contact_mobile: z.string().optional(),
  latitude: coerceToOptionalNumber,
  longitude: coerceToOptionalNumber,
  animal_type: coerceToOptionalString,
  lactation: coerceToOptionalString,
  milk_per_day: coerceToOptionalNumber,
});

exports.commentSchema = z.object({
  content: z.string().min(1, 'Comment cannot be empty'),
});
