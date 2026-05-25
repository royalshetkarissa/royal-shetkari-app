const authService = require('../services/authService');
const { logActivity } = require('../utils/logger');
const AppError = require('../utils/AppError');

exports.register = async (req, res, next) => {
  try {
    const { fullName, mobile, email, password, village, state, pincode } = req.body;
    
    const existingUser = await authService.findUserByMobile(mobile);
    if (existingUser) {
      return next(new AppError('Mobile number already registered', 400));
    }
    
    await authService.createUser({ fullName, mobile, email, password, village, state, pincode });
    const devOtp = await authService.createOTP(mobile);
    
    console.log('🔐 OTP for', mobile, ':', devOtp);
    res.status(201).json({ success: true, message: 'OTP sent successfully', devOtp, mobile, requestId: req.id });
  } catch (error) {
    next(error);
  }
};

exports.login = async (req, res, next) => {
  try {
    const { mobile, password } = req.body;
    
    const user = await authService.findUserByMobile(mobile);
    if (!user) {
      return next(new AppError('Mobile number not found', 401));
    }
    
    const isMatch = await authService.comparePassword(password, user.password);
    if (!isMatch) {
      return next(new AppError('Invalid password', 401));
    }
    
    const devOtp = await authService.createOTP(mobile);
    
    console.log('🔐 OTP for', mobile, ':', devOtp);
    res.json({ success: true, message: 'OTP sent', devOtp, mobile, requestId: req.id });
  } catch (error) {
    next(error);
  }
};

const refreshTokenService = require('../services/refreshTokenService');

exports.verifyOtp = async (req, res, next) => {
  try {
    const { mobile, otp } = req.body;
    
    const otpRecord = await authService.verifyOTP(mobile, otp);
    if (!otpRecord) {
      return next(new AppError('Invalid or expired OTP', 400));
    }
    
    const user = await authService.findUserByMobile(mobile);
    const { accessToken } = authService.generateTokens(user);
    const refreshToken = await refreshTokenService.createToken(user.id);
    
    await logActivity(user.id, 'LOGIN', 'user', user.id, { mobile }, req.id);
    res.json({ success: true, token: accessToken, accessToken, refreshToken, user, requestId: req.id });
  } catch (error) {
    next(error);
  }
};

exports.refreshToken = async (req, res, next) => {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return next(new AppError('Refresh token required', 400));

    const tokenRecord = await refreshTokenService.verifyToken(refreshToken);
    if (!tokenRecord) return next(new AppError('Invalid or expired refresh token', 401));

    const user = await authService.findUserById(tokenRecord.user_id);
    const { accessToken } = authService.generateTokens(user);

    res.json({ success: true, accessToken, requestId: req.id });
  } catch (error) {
    next(error);
  }
};

exports.updateProfile = async (req, res, next) => {
  try {
    const user = await authService.updateProfile(req.userId, req.body);
    await logActivity(req.userId, 'UPDATE_PROFILE', 'user', req.userId, { fields: Object.keys(req.body) }, req.id);
    res.json({ success: true, user, requestId: req.id });
  } catch (error) {
    next(error);
  }
};

exports.updateProfilePhoto = async (req, res, next) => {
  try {
    if (!req.file) return next(new AppError('No photo provided', 400));
    
    const photoUrl = `/uploads/${req.file.filename}`;
    await authService.updateProfilePhoto(req.userId, photoUrl);
    await logActivity(req.userId, 'UPDATE_PHOTO', 'user', req.userId, { photo_url: photoUrl }, req.id);
    
    res.json({ success: true, photoUrl, requestId: req.id });
  } catch (error) {
    next(error);
  }
};

exports.getMe = async (req, res, next) => {
  try {
    const user = await authService.findUserById(req.userId);
    res.json({ success: true, user, requestId: req.id });
  } catch (error) {
    next(error);
  }
};

exports.resendOtp = async (req, res, next) => {
  try {
    const { mobile } = req.body;
    const devOtp = await authService.createOTP(mobile);
    res.json({ success: true, message: 'OTP sent', devOtp, requestId: req.id });
  } catch (error) {
    next(error);
  }
};

exports.resetPassword = async (req, res, next) => {
  try {
    const { mobile, newPassword } = req.body;
    
    const user = await authService.findUserByMobile(mobile);
    if (!user) {
      return next(new AppError('Mobile number not registered', 404));
    }
    
    const updatedUser = await authService.resetPassword(mobile, newPassword);
    
    // Log the security event in user change history/audit log
    await logActivity(
      user.id,
      'PASSWORD_RESET',
      'user',
      user.id,
      { mobile, details: 'Password reset from login screen screen bypass/reset button' },
      req.id
    );
    
    res.json({
      success: true,
      message: 'Password reset successfully',
      user: {
        id: updatedUser.id,
        fullName: updatedUser.full_name,
        mobile: updatedUser.mobile
      }
    });
  } catch (error) {
    next(error);
  }
};
