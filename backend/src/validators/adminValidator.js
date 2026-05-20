const { z } = require('zod');

exports.updateAccessSchema = z.object({
  targetUserId: z.string().or(z.number()),
  role: z.enum(['admin', 'farmer', 'expert', 'support']),
  isAdmin: z.boolean(),
  permissions: z.array(z.string()).optional(),
});
