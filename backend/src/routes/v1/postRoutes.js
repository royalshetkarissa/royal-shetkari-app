const express = require('express');
const router = express.Router();
const postController = require('../../controllers/postController');
const { verifyToken } = require('../../middleware/auth');
const upload = require('../../middleware/upload');

const validate = require('../../middleware/validate');
const {
  createPostSchema,
  updatePostSchema,
  commentSchema,
} = require('../../validators/postValidator');

router.get('/', postController.getPosts);
router.get('/:id', postController.getPostDetails);
router.get('/:id/comments', postController.getComments);

router.post(
  '/',
  verifyToken,
  upload.array('images', 5),
  validate(createPostSchema),
  postController.createPost
);
router.post('/:id/like', verifyToken, postController.likePost);
router.post('/:id/save', verifyToken, postController.savePost);
router.post('/:id/comments', verifyToken, validate(commentSchema), postController.addComment);
router.post('/:id/wp-click', postController.trackWpClick);
router.post('/:id/call-click', postController.trackCallClick);

router.delete('/:id', verifyToken, postController.deletePost);
router.put('/:id', verifyToken, validate(updatePostSchema), postController.updatePost);

module.exports = router;
