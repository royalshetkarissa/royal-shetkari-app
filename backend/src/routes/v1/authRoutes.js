const express = require('express');
const router = express.Router();
const authController = require('../../controllers/authController');
const { verifyToken } = require('../../middleware/auth');
const upload = require('../../middleware/upload');

const validate = require('../../middleware/validate');
const {
  registerSchema,
  loginSchema,
  otpSchema,
  updateProfileSchema,
  resendOtpSchema,
  resetPasswordSchema,
} = require('../../validators/authValidator');

const { authLimiter } = require('../../middleware/security');

router.get('/', (req, res) => {
  res.json({
    status: 'success',
    message: 'Auth API is fully functional!',
    timestamp: new Date().toISOString(),
  });
});

router.post('/register', validate(registerSchema), authController.register);
router.post('/login', authLimiter, validate(loginSchema), authController.login);
router.post('/verify-otp', validate(otpSchema), authController.verifyOtp);
router.post('/resend-otp', validate(resendOtpSchema), authController.resendOtp);
router.post('/reset-password', validate(resetPasswordSchema), authController.resetPassword);
router.post('/refresh-token', authController.refreshToken);

const postController = require('../../controllers/postController');

router.put(
  '/user/profile',
  verifyToken,
  validate(updateProfileSchema),
  authController.updateProfile
);
router.post(
  '/user/profile/photo',
  verifyToken,
  upload.single('photo'),
  authController.updateProfilePhoto
);
router.get('/user/me', verifyToken, authController.getMe);

router.get('/user/posts', verifyToken, postController.getUserPosts);
router.get('/user/social-stats', verifyToken, postController.getUserSocialStats);
router.get('/user/saved-posts', verifyToken, postController.getSavedPosts);

module.exports = router;
