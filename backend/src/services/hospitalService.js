const hospitalRepository = require('../repositories/hospitalRepository');

class HospitalService {
  async addHospital(data) {
    return await hospitalRepository.create(data);
  }

  async getActiveHospitals() {
    return await hospitalRepository.findActive();
  }

  async deleteHospital(id) {
    return await hospitalRepository.delete(id);
  }

  async redeemCoins(userId, hospitalId) {
    // 1. Check user coins
    const coins = await hospitalRepository.getUserCoins(userId);
    if (coins < 50) {
      throw new Error('Insufficient coins. Minimum 50 coins required for redemption.');
    }

    // 2. Find hospital
    const hospital = await hospitalRepository.findById(hospitalId);
    if (!hospital || hospital.status === 'deleted') {
      throw new Error('Hospital not found or is no longer active.');
    }

    // 3. Perform atomic transaction
    return await hospitalRepository.redeemCoins(userId, hospitalId);
  }

  async getAllRedemptions() {
    return await hospitalRepository.getRedemptions();
  }

  async getRedemptionHistory(userId) {
    return await hospitalRepository.getHistoryByUserId(userId);
  }
}

module.exports = new HospitalService();
