const diseaseRepository = require('../repositories/diseaseRepository');

class DiseaseService {
  async scanDisease(userId, imageUrl) {
    // MOCK RESPONSE for now until Python AI API is integrated
    const mockResponse = {
      diseaseName: 'Early Blight (Alternaria solani)',
      chemicalSolution:
        'Apply Mancozeb 75% WP @ 2.5g/L of water or Chlorothalonil 75% WP @ 2g/L of water.',
      organicSolution:
        'Spray Copper fungicide or Neem oil extract (1500 PPM) @ 5ml/L of water. Ensure proper crop spacing and avoid overhead watering.',
    };

    // Save to history
    const historyRecord = await diseaseRepository.saveHistory({
      userId,
      imageUrl,
      diseaseName: mockResponse.diseaseName,
      chemicalSolution: mockResponse.chemicalSolution,
      organicSolution: mockResponse.organicSolution,
    });

    return historyRecord;
  }

  async getHistory(userId) {
    return await diseaseRepository.getHistoryByUserId(userId);
  }

  async softDelete(id, userId) {
    return await diseaseRepository.softDeleteHistory(id, userId);
  }
}

module.exports = new DiseaseService();
