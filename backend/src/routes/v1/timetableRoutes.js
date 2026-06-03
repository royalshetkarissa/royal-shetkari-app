const express = require('express');
const router = express.Router();
const timetableController = require('../../controllers/timetableController');
const { verifyToken } = require('../../middleware/auth');

// Public/User Routes
router.get('/crops', verifyToken, timetableController.getAvailableCrops);
router.post('/start-journey', verifyToken, timetableController.startJourney);
router.get('/my-journeys', verifyToken, timetableController.getMyJourneys);
router.get('/daily-tasks', verifyToken, timetableController.getDailyTasks);
router.patch('/tasks/:taskId/complete', verifyToken, timetableController.completeTask);
router.get('/crops/:cropId/diseases', verifyToken, timetableController.getCropDiseases);
router.delete('/journey/:id', verifyToken, timetableController.deleteJourney);

module.exports = router;
