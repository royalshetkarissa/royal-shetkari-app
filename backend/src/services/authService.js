const bcrypt = require('bcrypt');
const userRepository = require('../repositories/userRepository');
const jwtHelper = require('../utils/jwtHelper');

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
    const otp = Math.floor(100000 + Math.random() * 900000).toString();
    const expiry = new Date();
    expiry.setMinutes(expiry.getMinutes() + 10);
    
    await userRepository.createOTP(mobile, otp, expiry);
    return otp;
  }

  async verifyOTP(mobile, otp) {
    const otpRecord = await userRepository.findValidOTP(mobile, otp);
    if (!otpRecord) return null;
    
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
      permissions: user.permissions
    };

    const accessToken = jwtHelper.signAccessToken(payload);
    return { accessToken };
  }

  async resetPassword(mobile, newPassword) {
    return await userRepository.updatePasswordByMobile(mobile, newPassword);
  }
}

module.exports = new AuthService();
