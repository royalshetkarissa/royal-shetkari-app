const bcrypt = require('bcrypt');
const userRepository = require('../repositories/userRepository');
const jwtHelper = require('../utils/jwtHelper');
const generateOtp = require('../utils/generateOtp');
const whatsappHelper = require('../utils/whatsappHelper');
const AppError = require('../utils/AppError');

class AuthService {
  async findUserByMobile(mobile) {
    return await userRepository.findByMobile(mobile);
  }

  async findUserById(id) {
    return await userRepository.findById(id);
  }

  async createUser(data) {
    return await userRepository.create(data);
  }

  async updateProfile(userId, data) {
    return await userRepository.updateProfile(userId, data);
  }

  async updateProfilePhoto(userId, photoUrl) {
    await userRepository.updateProfilePhoto(userId, photoUrl);
  }

  async createOTP(mobile) {
    const otp = generateOtp();
    const expiry = new Date();
    expiry.setMinutes(expiry.getMinutes() + 5);

    await userRepository.createOTP(mobile, otp, expiry);
    await whatsappHelper.sendWhatsAppOtp(mobile, otp);
    return otp;
  }

  async verifyOTP(mobile, otp) {
    const otpRecord = await userRepository.getLatestOTP(mobile);
    if (!otpRecord) {
      throw new AppError('Invalid or expired OTP', 400);
    }

    if (otpRecord.attempts >= 5) {
      throw new AppError('Too many failed attempts. Please request a new OTP.', 400);
    }

    if (otpRecord.otp !== otp) {
      await userRepository.incrementOTPAttempts(otpRecord.id);
      throw new AppError('Invalid OTP', 400);
    }

    await userRepository.useOTP(otpRecord.id);
    await userRepository.verifyUser(mobile);

    return otpRecord;
  }

  async comparePassword(candidate, hash) {
    return await bcrypt.compare(candidate, hash);
  }

  generateTokens(user) {
    const payload = {
      id: user.id,
      mobile: user.mobile,
      name: user.full_name,
      isAdmin: user.is_admin,
      role: user.role,
      permissions: user.permissions,
    };

    const accessToken = jwtHelper.signAccessToken(payload);
    return { accessToken };
  }

  async resetPassword(mobile, newPassword) {
    return await userRepository.updatePasswordByMobile(mobile, newPassword);
  }
}

module.exports = new AuthService();
