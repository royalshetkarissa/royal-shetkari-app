const diseaseService = require('../services/diseaseService');
const AppError = require('../utils/AppError');
const { uploadToB2IfNeeded } = require('../utils/b2Uploader');

const queues = require('../config/queue');

exports.scanDisease = async (req, res, next) => {
  try {
    let imageUrl = null;
    if (req.file) {
      imageUrl = await uploadToB2IfNeeded(req.file, 'disease');
    } else {
      return next(new AppError('Image is required for scanning', 400));
    }

    // Dispatch job to BullMQ queue
    const job = await queues.diseaseScanQueue.add('scan', {
      userId: req.userId,
      imageUrl,
    });

    res.status(202).json({ success: true, message: 'Processing started', jobId: job.id });
  } catch (error) {
    next(error);
  }
};

exports.getScanStatus = async (req, res, next) => {
  try {
    const { jobId } = req.params;
    const job = await queues.diseaseScanQueue.getJob(jobId);

    if (!job) {
      return next(new AppError('Job not found', 404));
    }

    const state = await job.getState();
    const result = job.returnvalue;

    res.json({
      success: true,
      jobId: job.id,
      state,
      result: result || null,
      failedReason: job.failedReason || null,
    });
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
