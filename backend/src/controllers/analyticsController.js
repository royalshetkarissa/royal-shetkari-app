const analyticsRepository = require('../repositories/analyticsRepository');
const AppError = require('../utils/AppError');

exports.logImpression = async (req, res, next) => {
  try {
    const { activeType, activeId, startTime, endTime, durationSeconds } = req.body;

    if (!activeType || !activeId || !startTime || !endTime || durationSeconds === undefined) {
      return next(new AppError('All impression metrics are required', 400));
    }

    const impression = await analyticsRepository.saveImpression({
      userId: req.userId || null,
      activeType,
      activeId: activeId.toString(),
      startTime,
      endTime,
      durationSeconds: parseInt(durationSeconds, 10),
    });

    res.status(201).json({
      success: true,
      message: 'Impression logged successfully',
      impression,
    });
  } catch (error) {
    next(error);
  }
};
