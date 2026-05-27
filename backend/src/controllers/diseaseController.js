const diseaseService = require('../services/diseaseService');
const AppError = require('../utils/AppError');

exports.scanDisease = async (req, res, next) => {
  try {
    let imageUrl = null;
    if (req.file) {
      imageUrl = `/uploads/${req.file.filename}`;
    } else {
      return next(new AppError('Image is required for scanning', 400));
    }

    const result = await diseaseService.scanDisease(req.userId, imageUrl);
    res.status(201).json({ success: true, data: result });
  } catch (error) {
    next(error);
  }
};

exports.getHistory = async (req, res, next) => {
  try {
    const history = await diseaseService.getHistory(req.userId);
    res.json({ success: true, history });
  } catch (error) {
    next(error);
  }
};

exports.deleteHistory = async (req, res, next) => {
  try {
    const record = await diseaseService.softDelete(req.params.id, req.userId);
    if (!record) return next(new AppError('Record not found or unauthorized', 404));

    res.json({ success: true, message: 'Record removed from history' });
  } catch (error) {
    next(error);
  }
};
