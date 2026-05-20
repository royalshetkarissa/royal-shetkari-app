const timetableService = require('../services/timetableService');
const AppError = require('../utils/AppError');

exports.getAvailableCrops = async (req, res, next) => {
  try {
    const crops = await timetableService.getAvailableCrops();
    res.json({ success: true, crops });
  } catch (error) {
    next(error);
  }
};

exports.startJourney = async (req, res, next) => {
  try {
    const { cropId, plantingDate } = req.body;
    if (!cropId || !plantingDate) {
      return next(new AppError('Crop ID and planting date are required', 400));
    }

    const journey = await timetableService.startCropJourney(req.userId, cropId, plantingDate);
    res.status(201).json({ success: true, journey });
  } catch (error) {
    next(error);
  }
};

exports.getMyJourneys = async (req, res, next) => {
  try {
    const journeys = await timetableService.getMyCropJourneys(req.userId);
    res.json({ success: true, journeys });
  } catch (error) {
    next(error);
  }
};

exports.completeTask = async (req, res, next) => {
  try {
    const { taskId } = req.params;
    const task = await timetableService.completeTask(req.userId, taskId);
    res.json({ success: true, task, message: 'Task completed! 1 coin awarded.' });
  } catch (error) {
    next(error);
  }
};

exports.deleteJourney = async (req, res, next) => {
  try {
    const { id } = req.params;
    await timetableService.deleteJourney(req.userId, id);
    res.json({ success: true, message: 'Journey deleted successfully.' });
  } catch (error) {
    next(error);
  }
};
