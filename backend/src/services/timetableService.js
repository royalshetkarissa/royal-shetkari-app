const timetableRepository = require('../repositories/timetableRepository');
const logger = require('../utils/logger');
const AppError = require('../utils/AppError');

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
      throw new AppError('Task already completed or not found.', 400);
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

  async getDailyTasks(userId, lang = 'en') {
    const rows = await timetableRepository.getDailyTasks(userId);
    const groupsMap = new Map();

    for (const row of rows) {
      const cropName = (lang === 'mr' && row.crop_marathi) ? row.crop_marathi : row.crop_name;
      const taskDescription = (lang === 'mr' && row.task_marathi) ? row.task_marathi : row.task_name;
      const organicProduct = row.organic_details || 'N/A';

      const plantingDate = new Date(row.planting_date);
      const dueDate = new Date(row.due_date);
      const dayOffset = Math.round((dueDate - plantingDate) / (1000 * 60 * 60 * 24));

      const groupKey = `${row.crop_name}_${dayOffset}`;

      if (!groupsMap.has(groupKey)) {
        groupsMap.set(groupKey, {
          cropName,
          dayOffset,
          tasks: []
        });
      }

      groupsMap.get(groupKey).tasks.push({
        task_description: taskDescription,
        organic_product: organicProduct
      });
    }

    return Array.from(groupsMap.values());
  }

  async getCropDiseases(cropId) {
    return await timetableRepository.getCropDiseases(cropId);
  }
}

module.exports = new TimetableService();
