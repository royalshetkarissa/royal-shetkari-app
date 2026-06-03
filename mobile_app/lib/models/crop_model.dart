class Crop {
  final int id;
  final String name;
  final String marathiName;
  final String category;
  final String iconName;

  Crop({
    required this.id,
    required this.name,
    required this.marathiName,
    required this.category,
    required this.iconName,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'],
      name: json['name'],
      marathiName: json['marathi_name'],
      category: json['category'],
      iconName: json['icon_name'] ?? 'eco',
    );
  }
}

class CropJourney {
  final int id;
  final int cropId;
  final String cropName;
  final String cropMarathi;
  final String iconName;
  final DateTime plantingDate;
  final List<CropTask> tasks;
  final int? harvestDaysMin;
  final int? harvestDaysMax;

  CropJourney({
    required this.id,
    required this.cropId,
    required this.cropName,
    required this.cropMarathi,
    required this.iconName,
    required this.plantingDate,
    required this.tasks,
    this.harvestDaysMin,
    this.harvestDaysMax,
  });

  factory CropJourney.fromJson(Map<String, dynamic> json) {
    return CropJourney(
      id: json['id'],
      cropId: json['crop_id'],
      cropName: json['crop_name'],
      cropMarathi: json['crop_marathi'],
      iconName: json['icon_name'] ?? 'eco',
      plantingDate: DateTime.parse(json['planting_date']),
      tasks: (json['tasks'] as List? ?? [])
          .map((t) => CropTask.fromJson(t))
          .toList(),
      harvestDaysMin: json['harvest_days_min'],
      harvestDaysMax: json['harvest_days_max'],
    );
  }
}

class CropTask {
  final int id;
  final String name;
  final String nameMarathi;
  final DateTime dueDate;
  final bool isCompleted;
  final bool coinAwarded;
  final String? organicDetails;
  final String? chemicalDetails;
  final String? rationaleEnglish;
  final String? rationaleMarathi;
  final String? nutrientContent;

  CropTask({
    required this.id,
    required this.name,
    required this.nameMarathi,
    required this.dueDate,
    required this.isCompleted,
    required this.coinAwarded,
    this.organicDetails,
    this.chemicalDetails,
    this.rationaleEnglish,
    this.rationaleMarathi,
    this.nutrientContent,
  });

  factory CropTask.fromJson(Map<String, dynamic> json) {
    return CropTask(
      id: json['id'],
      name: json['task_name'],
      nameMarathi: json['task_marathi'],
      dueDate: DateTime.parse(json['due_date']),
      isCompleted: json['is_completed'] ?? false,
      coinAwarded: json['coin_awarded'] ?? false,
      organicDetails: json['organic_details'],
      chemicalDetails: json['chemical_details'],
      rationaleEnglish: json['rationale_english'],
      rationaleMarathi: json['rationale_marathi'],
      nutrientContent: json['nutrient_content'],
    );
  }
}

class CropDisease {
  final int id;
  final int cropId;
  final String name;
  final String nameMarathi;
  final String stage;
  final String stageMarathi;
  final String symptoms;
  final String symptomsMarathi;
  final String organicPrevention;
  final String organicPreventionMarathi;
  final String severity;

  CropDisease({
    required this.id,
    required this.cropId,
    required this.name,
    required this.nameMarathi,
    required this.stage,
    required this.stageMarathi,
    required this.symptoms,
    required this.symptomsMarathi,
    required this.organicPrevention,
    required this.organicPreventionMarathi,
    required this.severity,
  });

  factory CropDisease.fromJson(Map<String, dynamic> json) {
    return CropDisease(
      id: json['id'],
      cropId: json['crop_id'],
      name: json['name'],
      nameMarathi: json['name_marathi'],
      stage: json['stage'],
      stageMarathi: json['stage_marathi'],
      symptoms: json['symptoms'],
      symptomsMarathi: json['symptoms_marathi'],
      organicPrevention: json['organic_prevention'],
      organicPreventionMarathi: json['organic_prevention_marathi'],
      severity: json['severity'] ?? 'Medium',
    );
  }
}
