const { z } = require('zod');

exports.registerSchema = z.object({
  fullName: z.string().min(3, 'Full name must be at least 3 characters'),
  mobile: z.string().min(10, 'Invalid mobile number').max(15),
  email: z.string().email('Invalid email address').optional().or(z.literal('')),
  password: z.string().min(6, 'Password must be at least 6 characters'),
  village: z.string().min(2, 'Village is required'),
  latitude: z.number().nullable().optional(),
  longitude: z.number().nullable().optional(),
  currentLocation: z.string().nullable().optional(),
});

exports.loginSchema = z.object({
  mobile: z.string().min(10).max(15),
  password: z.string().min(6),
});

exports.otpSchema = z.object({
  mobile: z.string(),
  otp: z.string().length(6),
  purpose: z.string().optional(),
});

exports.updateProfileSchema = z.object({
  fullName: z.string().min(3).optional(),
  email: z.string().email().optional().or(z.literal('')),
  village: z.string().min(2).optional(),
  state: z.string().optional(),
  pincode: z.string().optional(),
  latitude: z.number().nullable().optional(),
  longitude: z.number().nullable().optional(),
  currentLocation: z.string().nullable().optional(),
});

exports.resendOtpSchema = z.object({
  mobile: z.string().min(10).max(15),
});
