const crypto = require('crypto');
const tokenRepository = require('../repositories/tokenRepository');

class RefreshTokenService {
  async createToken(userId) {
    const token = crypto.randomBytes(40).toString('hex');
    const expiresAt = new Date();
    expiresAt.setDate(expiresAt.getDate() + 7); // 7 days

    await tokenRepository.create(userId, token, expiresAt);
    return token;
  }

  async verifyToken(token) {
    return await tokenRepository.findByToken(token);
  }

  async deleteToken(token) {
    await tokenRepository.delete(token);
  }

  async deleteAllForUser(userId) {
    await tokenRepository.deleteAllForUser(userId);
  }
}

module.exports = new RefreshTokenService();
