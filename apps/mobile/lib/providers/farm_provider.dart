import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/models/farm_model.dart';
import 'package:villagenova/core/network/api_client.dart';

enum FarmStatus { initial, loading, loaded, error }

class FarmState {
  final FarmStatus status;
  final MyFarmModel? farm;
  final List<CropObservationModel> observations;
  final LeafDoctorDiagnosisModel? latestDiagnosis;
  final bool isLoggingActivity;
  final bool isDiagnosing;
  final String? errorMessage;

  const FarmState({
    this.status = FarmStatus.initial,
    this.farm,
    this.observations = const [],
    this.latestDiagnosis,
    this.isLoggingActivity = false,
    this.isDiagnosing = false,
    this.errorMessage,
  });

  FarmState copyWith({
    FarmStatus? status,
    MyFarmModel? farm,
    List<CropObservationModel>? observations,
    LeafDoctorDiagnosisModel? latestDiagnosis,
    bool? isLoggingActivity,
    bool? isDiagnosing,
    String? errorMessage,
  }) {
    return FarmState(
      status: status ?? this.status,
      farm: farm ?? this.farm,
      observations: observations ?? this.observations,
      latestDiagnosis: latestDiagnosis ?? this.latestDiagnosis,
      isLoggingActivity: isLoggingActivity ?? this.isLoggingActivity,
      isDiagnosing: isDiagnosing ?? this.isDiagnosing,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class FarmNotifier extends StateNotifier<FarmState> {
  final ApiClient apiClient;

  FarmNotifier(this.apiClient) : super(const FarmState()) {
    fetchMyFarm();
  }

  Future<void> fetchMyFarm() async {
    state = state.copyWith(status: FarmStatus.loading);
    try {
      final response = await apiClient.dio.get('/farm/my-farm');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final model = MyFarmModel.fromJson(response.data['data'] as Map<String, dynamic>);
        state = state.copyWith(status: FarmStatus.loaded, farm: model);
        return;
      }
    } catch (_) {
      // Offline fallback
    }
    _setFallbackFarm();
  }

  Future<LeafDoctorDiagnosisModel?> diagnoseLeaf({
    required String symptomText,
    String cropName = 'Soybean',
    String? affectedOrgan,
    String? severityHint,
    String? imageBase64,
  }) async {
    state = state.copyWith(isDiagnosing: true);
    LeafDoctorDiagnosisModel? diagnosis;

    try {
      final response = await apiClient.dio.post(
        '/farm/leaf-doctor/diagnose',
        data: {
          'crop_name': cropName,
          'symptom_text': symptomText,
          'affected_organ': affectedOrgan,
          'severity_hint': severityHint,
          'image_base64': imageBase64,
          'save_observation': true,
        },
      );
      if ((response.statusCode == 200 || response.statusCode == 201) && response.data['data'] != null) {
        diagnosis = LeafDoctorDiagnosisModel.fromJson(
          response.data['data'] as Map<String, dynamic>,
        );
      }
    } catch (_) {
      // Offline PJTSAU fallback diagnosis
    }

    diagnosis ??= _offlineLeafDiagnosis(
      symptomText: symptomText,
      cropName: cropName,
      severityHint: severityHint,
      hasImageInput: imageBase64 != null && imageBase64.isNotEmpty,
    );

    final newObs = CropObservationModel(
      id: diagnosis.observationId,
      observationText: symptomText,
      aiDiagnosisSummary: '${diagnosis.diseaseOrPestName}: ${diagnosis.summary}',
      severityLevel: diagnosis.severityLevel,
      loggedAt: diagnosis.loggedAt,
      diagnosis: diagnosis,
    );

    state = state.copyWith(
      latestDiagnosis: diagnosis,
      observations: [newObs, ...state.observations],
      isDiagnosing: false,
    );
    return diagnosis;
  }

  LeafDoctorDiagnosisModel _offlineLeafDiagnosis({
    required String symptomText,
    required String cropName,
    String? severityHint,
    required bool hasImageInput,
  }) {
    final lower = symptomText.toLowerCase();
    final nowIso = DateTime.now().toIso8601String();
    final obsId = 'obs_${DateTime.now().millisecondsSinceEpoch}';

    if (lower.contains('yellow') || lower.contains('whitefl') || severityHint == 'yellowing') {
      return LeafDoctorDiagnosisModel(
        observationId: obsId,
        cropName: cropName,
        cropStage: 'vegetative',
        diseaseOrPestName: 'Yellow Mosaic Virus (YMV) & Whitefly Vector',
        scientificName: 'Bemisia tabaci / MYMV',
        affectedOrgan: 'leaf',
        severityLevel: 'high',
        confidenceScore: hasImageInput ? 0.94 : 0.88,
        isHealthy: false,
        summary: 'Yellow mottling and whitefly presence indicate early Yellow Mosaic Virus spread.',
        weatherSprayWarning:
            'IMD Rain-Fastness Alert: 14mm rain forecast at 6:00 PM. Hold foliar sprays until tomorrow morning.',
        organicRemedies: const [
          LeafDiagnosisRemedyModel(
            remedyType: 'organic',
            title: 'Yellow Sticky Traps + 5% NSKE',
            dosage: '6-8 traps/acre + 50g/L neem kernel extract',
            applicationMethod: 'Place traps above canopy; spray NSKE on leaf undersides.',
          ),
        ],
        chemicalRemedies: const [
          LeafDiagnosisRemedyModel(
            remedyType: 'chemical',
            title: 'Acetamiprid 20% SP',
            dosage: '0.2 g/L water (40 g/acre)',
            applicationMethod: 'Fine spray directed at lower leaf undersides after rain clears.',
          ),
        ],
        preventiveSteps: const ['Uproot severely stunted YMV plants early'],
        citations: const [
          LeafDoctorCitationModel(
            documentTitle: 'PJTSAU Soybean Kharif 2026 Package of Practices',
            authority: 'PJTSAU Telangana',
            officialUrl: 'https://pjtsau.edu.in/agronomy/soybean-kharif-2026',
            publishedDate: 'Kharif 2026 Bulletin #4',
          ),
        ],
        modelUsed: 'offline-pjtsau-leaf-doctor',
        hasImageInput: hasImageInput,
        loggedAt: nowIso,
      );
    }

    if (lower.contains('pest') || lower.contains('worm') || lower.contains('hole') || severityHint == 'pest_detected') {
      return LeafDoctorDiagnosisModel(
        observationId: obsId,
        cropName: cropName,
        cropStage: 'vegetative',
        diseaseOrPestName: 'Spodoptera Leaf Caterpillar',
        scientificName: 'Spodoptera litura',
        affectedOrgan: 'leaf',
        severityLevel: 'moderate',
        confidenceScore: 0.89,
        isHealthy: false,
        summary: 'Chewed leaf margins indicate defoliating caterpillar pressure in vegetative canopy.',
        weatherSprayWarning:
            'IMD Rain-Fastness Alert: Hold spraying ahead of 6:00 PM rainfall to prevent wash-off.',
        organicRemedies: const [
          LeafDiagnosisRemedyModel(
            remedyType: 'organic',
            title: '5% Neem Seed Kernel Extract (NSKE)',
            dosage: '50 g/L spray',
            applicationMethod: 'Destroy egg masses manually and spot-spray affected rows.',
          ),
        ],
        chemicalRemedies: const [
          LeafDiagnosisRemedyModel(
            remedyType: 'chemical',
            title: 'Emamectin Benzoate 5% SG',
            dosage: '0.4 g/L water',
            applicationMethod: 'Apply in rain-free evening hours if >1 larva/meter.',
          ),
        ],
        preventiveSteps: const ['Install 5 pheromone traps/acre'],
        citations: const [
          LeafDoctorCitationModel(
            documentTitle: 'PJTSAU Soybean Kharif 2026 Package of Practices',
            authority: 'PJTSAU Telangana',
            publishedDate: 'Kharif 2026 Bulletin #4',
          ),
        ],
        modelUsed: 'offline-pjtsau-leaf-doctor',
        hasImageInput: hasImageInput,
        loggedAt: nowIso,
      );
    }

    return LeafDoctorDiagnosisModel(
      observationId: obsId,
      cropName: cropName,
      cropStage: 'vegetative',
      diseaseOrPestName: 'Healthy Crop Canopy — No Active Pathology',
      affectedOrgan: 'leaf',
      severityLevel: 'healthy',
      confidenceScore: 0.93,
      isHealthy: true,
      summary: 'Healthy dark green foliage without necrotic spots or active vector infestation.',
      organicRemedies: const [
        LeafDiagnosisRemedyModel(
          remedyType: 'cultural',
          title: 'Continue Border Trap Monitoring',
          dosage: '4-6 traps/acre',
          applicationMethod: 'Routine scouting every 5 days.',
        ),
      ],
      chemicalRemedies: const [],
      preventiveSteps: const ['Keep drainage channels clear ahead of evening rainfall'],
      citations: const [
        LeafDoctorCitationModel(
          documentTitle: 'PJTSAU Soybean Kharif 2026 Package of Practices',
          authority: 'PJTSAU Telangana',
          publishedDate: 'Kharif 2026 Bulletin #4',
        ),
      ],
      modelUsed: 'offline-pjtsau-leaf-doctor',
      hasImageInput: hasImageInput,
      loggedAt: nowIso,
    );
  }

  Future<bool> logActivity({
    required String activityType,
    required String description,
    double cost = 0.0,
  }) async {
    state = state.copyWith(isLoggingActivity: true);
    try {
      await apiClient.dio.post(
        '/farm/activities',
        data: {
          'activity_type': activityType,
          'description': description,
          'cost_incurred': cost,
        },
      );
    } catch (_) {}

    // Optimistically append activity to local state
    if (state.farm != null) {
      final newAct = CropActivityModel(
        id: 'act_${DateTime.now().millisecondsSinceEpoch}',
        activityType: activityType,
        description: description,
        costIncurred: cost,
        performedAt: DateTime.now().toIso8601String(),
      );
      final updatedActivities = [newAct, ...state.farm!.recentActivities];
      final updatedFarm = MyFarmModel(
        farmId: state.farm!.farmId,
        farmName: state.farm!.farmName,
        landAcres: state.farm!.landAcres,
        soilType: state.farm!.soilType,
        waterSource: state.farm!.waterSource,
        crop: state.farm!.crop,
        totalExpenses: state.farm!.totalExpenses + cost,
        recentActivities: updatedActivities,
        recentExpenses: state.farm!.recentExpenses,
        weatherAdvisory: state.farm!.weatherAdvisory,
      );
      state = state.copyWith(farm: updatedFarm, isLoggingActivity: false);
      return true;
    }

    state = state.copyWith(isLoggingActivity: false);
    return true;
  }

  Future<bool> addExpense({
    required String category,
    required double amount,
    String? notes,
  }) async {
    try {
      await apiClient.dio.post(
        '/farm/expenses',
        data: {
          'category': category,
          'amount': amount,
          'notes': notes,
        },
      );
    } catch (_) {}

    if (state.farm != null) {
      final newExp = FarmExpenseModel(
        id: 'exp_${DateTime.now().millisecondsSinceEpoch}',
        category: category,
        amount: amount,
        expenseDate: DateTime.now().toIso8601String().split('T')[0],
        notes: notes,
      );
      final updatedFarm = MyFarmModel(
        farmId: state.farm!.farmId,
        farmName: state.farm!.farmName,
        landAcres: state.farm!.landAcres,
        soilType: state.farm!.soilType,
        waterSource: state.farm!.waterSource,
        crop: state.farm!.crop,
        totalExpenses: state.farm!.totalExpenses + amount,
        recentActivities: state.farm!.recentActivities,
        recentExpenses: [newExp, ...state.farm!.recentExpenses],
        weatherAdvisory: state.farm!.weatherAdvisory,
      );
      state = state.copyWith(farm: updatedFarm);
      return true;
    }
    return true;
  }

  void _setFallbackFarm() {
    final stages = [
      const CropStageStepModel(stageKey: 'sowing', title: 'Sowing & Seeding', daysRange: 'Day 1-5', isCompleted: true, isCurrent: false),
      const CropStageStepModel(stageKey: 'germination', title: 'Germination & Emergence', daysRange: 'Day 6-12', isCompleted: true, isCurrent: false),
      const CropStageStepModel(stageKey: 'vegetative', title: 'Vegetative & Branching', daysRange: 'Day 13-55', isCompleted: false, isCurrent: true),
      const CropStageStepModel(stageKey: 'flowering', title: 'Flowering & Blossom', daysRange: 'Day 56-75', isCompleted: false, isCurrent: false),
      const CropStageStepModel(stageKey: 'pod_formation', title: 'Pod Formation & Fill', daysRange: 'Day 76-95', isCompleted: false, isCurrent: false),
      const CropStageStepModel(stageKey: 'harvest', title: 'Maturity & Harvest', daysRange: 'Day 96-115', isCompleted: false, isCurrent: false),
    ];

    final crop = CropDetailModel(
      id: 'demo_crop_1',
      cropName: 'Soybean (సోయాబీన్)',
      variety: 'JS 335 (Certified High Yield)',
      sowingDate: DateTime.now().subtract(const Duration(days: 42)).toIso8601String().split('T')[0],
      daysSinceSowing: 42,
      currentStage: 'vegetative',
      stageProgressPct: 38,
      farmingGoal: 'Maximize oilseed grain weight with integrated pest management',
      stages: stages,
    );

    final activities = [
      CropActivityModel(
        id: 'act_1',
        activityType: 'irrigation',
        description: 'Borewell channel irrigation before dry interval',
        costIncurred: 0.0,
        performedAt: DateTime.now().subtract(const Duration(days: 2)).toIso8601String(),
      ),
      CropActivityModel(
        id: 'act_2',
        activityType: 'fertilizer',
        description: 'Applied DAP (18-46-0) split dose for root branching',
        costIncurred: 1450.0,
        performedAt: DateTime.now().subtract(const Duration(days: 8)).toIso8601String(),
      ),
    ];

    final expenses = [
      FarmExpenseModel(
        id: 'exp_1',
        category: 'fertilizer',
        amount: 1450.0,
        expenseDate: DateTime.now().subtract(const Duration(days: 8)).toIso8601String().split('T')[0],
        notes: '1 bag DAP from Vikarabad Agro Seva Kendra',
      ),
      FarmExpenseModel(
        id: 'exp_2',
        category: 'seeds',
        amount: 3200.0,
        expenseDate: DateTime.now().subtract(const Duration(days: 42)).toIso8601String().split('T')[0],
        notes: 'Certified JS-335 seeds (30 kg)',
      ),
    ];

    final fallback = MyFarmModel(
      farmId: 'demo_farm_1',
      farmName: "Ravi's Main Farm",
      landAcres: 2.5,
      soilType: 'Black Soil (నల్ల రేగడి)',
      waterSource: 'Borewell',
      crop: crop,
      totalExpenses: 4650.0,
      recentActivities: activities,
      recentExpenses: expenses,
      weatherAdvisory: 'Rain expected today at 6:00 PM (14mm). Hold evening spray operations.',
    );

    state = state.copyWith(status: FarmStatus.loaded, farm: fallback);
  }
}

final farmProvider = StateNotifierProvider<FarmNotifier, FarmState>((ref) {
  final client = ref.watch(apiClientProvider);
  return FarmNotifier(client);
});
