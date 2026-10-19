class CropStageStepModel {
  final String stageKey;
  final String title;
  final String daysRange;
  final bool isCompleted;
  final bool isCurrent;

  const CropStageStepModel({
    required this.stageKey,
    required this.title,
    required this.daysRange,
    required this.isCompleted,
    required this.isCurrent,
  });

  factory CropStageStepModel.fromJson(Map<String, dynamic> json) {
    return CropStageStepModel(
      stageKey: json['stage_key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      daysRange: json['days_range'] as String? ?? '',
      isCompleted: json['is_completed'] as bool? ?? false,
      isCurrent: json['is_current'] as bool? ?? false,
    );
  }
}

class CropActivityModel {
  final String id;
  final String activityType;
  final String? description;
  final double costIncurred;
  final String performedAt;

  const CropActivityModel({
    required this.id,
    required this.activityType,
    this.description,
    required this.costIncurred,
    required this.performedAt,
  });

  factory CropActivityModel.fromJson(Map<String, dynamic> json) {
    return CropActivityModel(
      id: json['id'] as String? ?? '',
      activityType: json['activity_type'] as String? ?? 'activity',
      description: json['description'] as String?,
      costIncurred: (json['cost_incurred'] as num?)?.toDouble() ?? 0.0,
      performedAt: json['performed_at'] as String? ?? '',
    );
  }
}

class FarmExpenseModel {
  final String id;
  final String category;
  final double amount;
  final String expenseDate;
  final String? notes;

  const FarmExpenseModel({
    required this.id,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.notes,
  });

  factory FarmExpenseModel.fromJson(Map<String, dynamic> json) {
    return FarmExpenseModel(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: json['expense_date'] as String? ?? '',
      notes: json['notes'] as String?,
    );
  }
}

class CropDetailModel {
  final String id;
  final String cropName;
  final String? variety;
  final String sowingDate;
  final int daysSinceSowing;
  final String currentStage;
  final int stageProgressPct;
  final String? farmingGoal;
  final List<CropStageStepModel> stages;

  const CropDetailModel({
    required this.id,
    required this.cropName,
    this.variety,
    required this.sowingDate,
    required this.daysSinceSowing,
    required this.currentStage,
    required this.stageProgressPct,
    this.farmingGoal,
    required this.stages,
  });

  factory CropDetailModel.fromJson(Map<String, dynamic> json) {
    return CropDetailModel(
      id: json['id'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? 'Crop',
      variety: json['variety'] as String?,
      sowingDate: json['sowing_date'] as String? ?? '',
      daysSinceSowing: json['days_since_sowing'] as int? ?? 0,
      currentStage: json['current_stage'] as String? ?? 'vegetative',
      stageProgressPct: json['stage_progress_pct'] as int? ?? 0,
      farmingGoal: json['farming_goal'] as String?,
      stages: (json['stages'] as List<dynamic>?)
              ?.map((e) => CropStageStepModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class MyFarmModel {
  final String farmId;
  final String farmName;
  final double landAcres;
  final String soilType;
  final String waterSource;
  final CropDetailModel? crop;
  final double totalExpenses;
  final List<CropActivityModel> recentActivities;
  final List<FarmExpenseModel> recentExpenses;
  final String weatherAdvisory;

  const MyFarmModel({
    required this.farmId,
    required this.farmName,
    required this.landAcres,
    required this.soilType,
    required this.waterSource,
    this.crop,
    required this.totalExpenses,
    required this.recentActivities,
    required this.recentExpenses,
    required this.weatherAdvisory,
  });

  factory MyFarmModel.fromJson(Map<String, dynamic> json) {
    return MyFarmModel(
      farmId: json['farm_id'] as String? ?? '',
      farmName: json['farm_name'] as String? ?? 'My Farm',
      landAcres: (json['land_acres'] as num?)?.toDouble() ?? 2.5,
      soilType: json['soil_type'] as String? ?? 'Black Soil',
      waterSource: json['water_source'] as String? ?? 'Borewell',
      crop: json['crop'] != null
          ? CropDetailModel.fromJson(json['crop'] as Map<String, dynamic>)
          : null,
      totalExpenses: (json['total_expenses'] as num?)?.toDouble() ?? 0.0,
      recentActivities: (json['recent_activities'] as List<dynamic>?)
              ?.map((e) => CropActivityModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recentExpenses: (json['recent_expenses'] as List<dynamic>?)
              ?.map((e) => FarmExpenseModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      weatherAdvisory: json['weather_advisory'] as String? ?? '',
    );
  }
}
