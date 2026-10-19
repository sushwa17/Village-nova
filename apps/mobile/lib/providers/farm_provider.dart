import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/models/farm_model.dart';
import 'package:villagenova/core/network/api_client.dart';
import 'package:villagenova/providers/auth_provider.dart';

enum FarmStatus { initial, loading, loaded, error }

class FarmState {
  final FarmStatus status;
  final MyFarmModel? farm;
  final bool isLoggingActivity;
  final String? errorMessage;

  const FarmState({
    this.status = FarmStatus.initial,
    this.farm,
    this.isLoggingActivity = false,
    this.errorMessage,
  });

  FarmState copyWith({
    FarmStatus? status,
    MyFarmModel? farm,
    bool? isLoggingActivity,
    String? errorMessage,
  }) {
    return FarmState(
      status: status ?? this.status,
      farm: farm ?? this.farm,
      isLoggingActivity: isLoggingActivity ?? this.isLoggingActivity,
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
