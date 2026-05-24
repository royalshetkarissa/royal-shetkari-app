const { z } = require('zod');

exports.updateAccessSchema = z.object({
  targetUserId: z.string().or(z.number()),
  role: z.enum(['user', 'moderator', 'admin', 'farmer', 'expert', 'support']),
  isAdmin: z.boolean(),
  permissions: z.record(z.boolean()).optional(),
});
