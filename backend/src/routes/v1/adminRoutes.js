const express = require('express');
const router = express.Router();
const adminController = require('../../controllers/adminController');
const { verifyAdmin, verifySuperUser } = require('../../middleware/auth');

const validate = require('../../middleware/validate');
const { updateAccessSchema } = require('../../validators/adminValidator');

router.get('/all-posts', verifyAdmin, adminController.getAllPosts);
router.get('/users', verifyAdmin, adminController.getUsers);
router.get('/stats/top-commenters', verifyAdmin, adminController.getTopCommenters);
router.get('/logs/moderation', verifyAdmin, adminController.getModerationLogs);
router.get('/users/:id/activity', verifyAdmin, adminController.getUserActivity);
router.get('/posts/:id/history', verifyAdmin, adminController.getPostHistory);
router.get('/users/:id/comments', verifyAdmin, adminController.getUserComments);

router.post(
  '/update-access',
  verifySuperUser,
  validate(updateAccessSchema),
  adminController.updateUserAccess
);
router.delete('/users/:id', verifySuperUser, adminController.deleteUser);

router.delete('/posts/:id', verifyAdmin, adminController.deletePost);
router.delete('/comments/:id', verifyAdmin, adminController.deleteComment);

module.exports = router;
