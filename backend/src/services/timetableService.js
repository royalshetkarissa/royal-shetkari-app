const timetableRepository = require('../repositories/timetableRepository');
const logger = require('../utils/logger');

class TimetableService {
  async getAvailableCrops() {
    return await timetableRepository.getAllCrops();
  }

  async startCropJourney(userId, cropId, plantingDate) {
    // 1. Create the journey
    const journey = await timetableRepository.createUserCropJourney(userId, cropId, plantingDate);

    // 2. Get templates for this crop
    const templates = await timetableRepository.getCropTemplates(cropId);

    // 3. Generate tasks based on planting date
    const tasks = templates.map((t) => {
      const dueDate = new Date(plantingDate);
      dueDate.setDate(dueDate.getDate() + t.day_offset);

      return {
        userCropId: journey.id,
        templateId: t.id,
        taskName: t.task_name,
        taskMarathi: t.task_marathi,
        dueDate: dueDate.toISOString().split('T')[0],
        organicDetails: t.organic_details,
        chemicalDetails: t.chemical_details,
        rationaleEnglish: t.rationale_english,
        rationaleMarathi: t.rationale_marathi,
        nutrientContent: t.nutrient_content,
      };
    });

    if (tasks.length > 0) {
      await timetableRepository.createUserCropTasks(tasks);
    }

    await logger.logActivity(userId, 'START_CROP_JOURNEY', 'crop_journey', journey.id, {
      cropId,
      plantingDate,
    });

    return journey;
  }

  async getMyCropJourneys(userId) {
    const journeys = await timetableRepository.getUserCropJourneys(userId);

    // Enrichment
    for (const journey of journeys) {
      journey.tasks = await timetableRepository.getTasksForJourney(journey.id);
    }

    return journeys;
  }

  async completeTask(userId, taskId) {
    const task = await timetableRepository.updateTaskCompletion(taskId, userId);
    if (!task) {
      throw new Error('Task already completed or not found.');
    }

    await logger.logActivity(userId, 'COMPLETE_CROP_TASK', 'crop_task', taskId, {
      taskName: task.task_name,
    });

    return task;
  }

  async deleteJourney(userId, journeyId) {
    await timetableRepository.deleteJourney(userId, journeyId);
    await logger.logActivity(userId, 'DELETE_CROP_JOURNEY', 'crop_journey', journeyId);
  }
}

module.exports = new TimetableService();
