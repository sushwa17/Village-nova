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

class CropLifecycleRiskModel {
  final String riskTitle;
  final String severity;
  final String mitigation;
  final String affectedOrgan;

  const CropLifecycleRiskModel({
    required this.riskTitle,
    required this.severity,
    required this.mitigation,
    required this.affectedOrgan,
  });

  factory CropLifecycleRiskModel.fromJson(Map<String, dynamic> json) {
    return CropLifecycleRiskModel(
      riskTitle: json['risk_title'] as String? ?? '',
      severity: json['severity'] as String? ?? 'low',
      mitigation: json['mitigation'] as String? ?? '',
      affectedOrgan: json['affected_organ'] as String? ?? 'leaf',
    );
  }
}

class CropStageRecommendationModel {
  final String category;
  final String title;
  final String guidance;
  final String source;

  const CropStageRecommendationModel({
    required this.category,
    required this.title,
    required this.guidance,
    required this.source,
  });

  factory CropStageRecommendationModel.fromJson(Map<String, dynamic> json) {
    return CropStageRecommendationModel(
      category: json['category'] as String? ?? 'cultural',
      title: json['title'] as String? ?? '',
      guidance: json['guidance'] as String? ?? '',
      source: json['source'] as String? ?? 'PJTSAU 2026 Package of Practices',
    );
  }
}

class CropLifecycleModel {
  final String cropName;
  final String variety;
  final String sowingDate;
  final int daysSinceSowing;
  final String currentStage;
  final String stageTitle;
  final String stageDaysRange;
  final int stageProgressPct;
  final int daysInCurrentStage;
  final int daysRemainingInStage;
  final int daysToHarvest;
  final String? farmingGoal;
  final List<CropStageStepModel> stages;
  final List<CropLifecycleRiskModel> activeRisks;
  final List<CropStageRecommendationModel> recommendations;
  final List<String> priorityActions;

  const CropLifecycleModel({
    required this.cropName,
    required this.variety,
    required this.sowingDate,
    required this.daysSinceSowing,
    required this.currentStage,
    required this.stageTitle,
    required this.stageDaysRange,
    required this.stageProgressPct,
    required this.daysInCurrentStage,
    required this.daysRemainingInStage,
    required this.daysToHarvest,
    this.farmingGoal,
    required this.stages,
    required this.activeRisks,
    required this.recommendations,
    required this.priorityActions,
  });

  factory CropLifecycleModel.fromJson(Map<String, dynamic> json) {
    return CropLifecycleModel(
      cropName: json['crop_name'] as String? ?? 'Soybean',
      variety: json['variety'] as String? ?? 'JS 335',
      sowingDate: json['sowing_date'] as String? ?? '',
      daysSinceSowing: json['days_since_sowing'] as int? ?? 0,
      currentStage: json['current_stage'] as String? ?? 'vegetative',
      stageTitle: json['stage_title'] as String? ?? '',
      stageDaysRange: json['stage_days_range'] as String? ?? '',
      stageProgressPct: json['stage_progress_pct'] as int? ?? 0,
      daysInCurrentStage: json['days_in_current_stage'] as int? ?? 0,
      daysRemainingInStage: json['days_remaining_in_stage'] as int? ?? 0,
      daysToHarvest: json['days_to_harvest'] as int? ?? 0,
      farmingGoal: json['farming_goal'] as String?,
      stages: (json['stages'] as List<dynamic>?)
              ?.map((e) => CropStageStepModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      activeRisks: (json['active_risks'] as List<dynamic>?)
              ?.map((e) => CropLifecycleRiskModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      recommendations: (json['recommendations'] as List<dynamic>?)
              ?.map((e) => CropStageRecommendationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      priorityActions: (json['priority_actions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }
}

class LeafDiagnosisRemedyModel {
  final String remedyType;
  final String title;
  final String dosage;
  final String applicationMethod;
  final String? safetyNote;

  const LeafDiagnosisRemedyModel({
    required this.remedyType,
    required this.title,
    required this.dosage,
    required this.applicationMethod,
    this.safetyNote,
  });

  factory LeafDiagnosisRemedyModel.fromJson(Map<String, dynamic> json) {
    return LeafDiagnosisRemedyModel(
      remedyType: json['remedy_type'] as String? ?? 'organic',
      title: json['title'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      applicationMethod: json['application_method'] as String? ?? '',
      safetyNote: json['safety_note'] as String?,
    );
  }
}

class LeafDoctorCitationModel {
  final String documentTitle;
  final String authority;
  final String? officialUrl;
  final String publishedDate;

  const LeafDoctorCitationModel({
    required this.documentTitle,
    required this.authority,
    this.officialUrl,
    required this.publishedDate,
  });

  factory LeafDoctorCitationModel.fromJson(Map<String, dynamic> json) {
    return LeafDoctorCitationModel(
      documentTitle: json['document_title'] as String? ?? '',
      authority: json['authority'] as String? ?? '',
      officialUrl: json['official_url'] as String?,
      publishedDate: json['published_date'] as String? ?? '2026',
    );
  }
}

class LeafDoctorDiagnosisModel {
  final String observationId;
  final String cropName;
  final String cropStage;
  final String diseaseOrPestName;
  final String? scientificName;
  final String affectedOrgan;
  final String severityLevel;
  final double confidenceScore;
  final bool isHealthy;
  final String summary;
  final String? weatherSprayWarning;
  final List<LeafDiagnosisRemedyModel> organicRemedies;
  final List<LeafDiagnosisRemedyModel> chemicalRemedies;
  final List<String> preventiveSteps;
  final List<LeafDoctorCitationModel> citations;
  final String modelUsed;
  final bool hasImageInput;
  final String loggedAt;

  const LeafDoctorDiagnosisModel({
    required this.observationId,
    required this.cropName,
    required this.cropStage,
    required this.diseaseOrPestName,
    this.scientificName,
    required this.affectedOrgan,
    required this.severityLevel,
    required this.confidenceScore,
    required this.isHealthy,
    required this.summary,
    this.weatherSprayWarning,
    required this.organicRemedies,
    required this.chemicalRemedies,
    required this.preventiveSteps,
    required this.citations,
    required this.modelUsed,
    required this.hasImageInput,
    required this.loggedAt,
  });

  factory LeafDoctorDiagnosisModel.fromJson(Map<String, dynamic> json) {
    return LeafDoctorDiagnosisModel(
      observationId: json['observation_id'] as String? ?? '',
      cropName: json['crop_name'] as String? ?? 'Soybean',
      cropStage: json['crop_stage'] as String? ?? 'vegetative',
      diseaseOrPestName: json['disease_or_pest_name'] as String? ?? 'Diagnostic Check',
      scientificName: json['scientific_name'] as String?,
      affectedOrgan: json['affected_organ'] as String? ?? 'leaf',
      severityLevel: json['severity_level'] as String? ?? 'mild',
      confidenceScore: (json['confidence_score'] as num?)?.toDouble() ?? 0.85,
      isHealthy: json['is_healthy'] as bool? ?? false,
      summary: json['summary'] as String? ?? '',
      weatherSprayWarning: json['weather_spray_warning'] as String?,
      organicRemedies: (json['organic_remedies'] as List<dynamic>?)
              ?.map((e) => LeafDiagnosisRemedyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      chemicalRemedies: (json['chemical_remedies'] as List<dynamic>?)
              ?.map((e) => LeafDiagnosisRemedyModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      preventiveSteps: (json['preventive_steps'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      citations: (json['citations'] as List<dynamic>?)
              ?.map((e) => LeafDoctorCitationModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      modelUsed: json['model_used'] as String? ?? 'pjtsau-pathology-engine',
      hasImageInput: json['has_image_input'] as bool? ?? false,
      loggedAt: json['logged_at'] as String? ?? '',
    );
  }
}

class CropObservationModel {
  final String id;
  final String observationText;
  final String? photoUrl;
  final String? aiDiagnosisSummary;
  final String severityLevel;
  final String loggedAt;
  final LeafDoctorDiagnosisModel? diagnosis;

  const CropObservationModel({
    required this.id,
    required this.observationText,
    this.photoUrl,
    this.aiDiagnosisSummary,
    required this.severityLevel,
    required this.loggedAt,
    this.diagnosis,
  });

  factory CropObservationModel.fromJson(Map<String, dynamic> json) {
    return CropObservationModel(
      id: json['id'] as String? ?? '',
      observationText: json['observation_text'] as String? ?? '',
      photoUrl: json['photo_url'] as String?,
      aiDiagnosisSummary: json['ai_diagnosis_summary'] as String?,
      severityLevel: json['severity_level'] as String? ?? 'mild',
      loggedAt: json['logged_at'] as String? ?? '',
      diagnosis: json['diagnosis'] != null
          ? LeafDoctorDiagnosisModel.fromJson(json['diagnosis'] as Map<String, dynamic>)
          : null,
    );
  }
}
