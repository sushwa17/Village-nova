import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/models/resident_model.dart';
import 'package:villagenova/providers/auth_provider.dart';
import 'package:villagenova/core/network/api_client.dart';

enum HomeStatus { initial, loading, loaded, error }

class HomeState {
  final HomeStatus status;
  final HomeDashboardModel? dashboard;
  final String? errorMessage;

  const HomeState({
    this.status = HomeStatus.initial,
    this.dashboard,
    this.errorMessage,
  });

  HomeState copyWith({
    HomeStatus? status,
    HomeDashboardModel? dashboard,
    String? errorMessage,
  }) {
    return HomeState(
      status: status ?? this.status,
      dashboard: dashboard ?? this.dashboard,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class HomeNotifier extends StateNotifier<HomeState> {
  final ApiClient apiClient;

  HomeNotifier(this.apiClient) : super(const HomeState());

  Future<void> fetchHomeDashboard() async {
    state = state.copyWith(status: HomeStatus.loading);
    try {
      final response = await apiClient.dio.get('/home');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final model = HomeDashboardModel.fromJson(response.data['data'] as Map<String, dynamic>);
        state = state.copyWith(status: HomeStatus.loaded, dashboard: model);
      } else {
        _setFallbackDashboard();
      }
    } catch (_) {
      // Offline resilient fallback
      _setFallbackDashboard();
    }
  }

  void toggleAction(String actionId) {
    if (state.dashboard == null) return;
    final updatedActions = state.dashboard!.todayActions.map((action) {
      if (action.id == actionId) {
        return TodayActionModel(
          id: action.id,
          title: action.title,
          tag: action.tag,
          actionType: action.actionType,
          completed: !action.completed,
        );
      }
      return action;
    }).toList();

    final completed = updatedActions.where((a) => a.completed).length;
    final total = updatedActions.length;
    final pct = total > 0 ? (completed / total * 100).toInt() : 0;

    final updatedModel = HomeDashboardModel(
      greeting: state.dashboard!.greeting,
      residentName: state.dashboard!.residentName,
      locationLabel: state.dashboard!.locationLabel,
      weatherHeadline: state.dashboard!.weatherHeadline,
      rainfallMm: state.dashboard!.rainfallMm,
      weatherAdvisory: state.dashboard!.weatherAdvisory,
      todayActions: updatedActions,
      completedTasks: completed,
      totalTasks: total,
      progressPercentage: pct,
    );

    state = state.copyWith(dashboard: updatedModel);
  }

  void _setFallbackDashboard() {
    final fallback = HomeDashboardModel(
      greeting: "Good morning, Ravi 👋",
      residentName: "Ravi",
      locationLabel: "Ananthagiri • Vikarabad",
      weatherHeadline: "Rain Expected Today (6:00 PM)",
      rainfallMm: 14.0,
      weatherAdvisory: "14mm forecast in your mandal. Avoid evening irrigation.",
      todayActions: [
        TodayActionModel(
          id: "act_1",
          title: "Check soil moisture before evening rain",
          tag: "💧 Irrigation",
          actionType: "check_soil",
          completed: true,
        ),
        TodayActionModel(
          id: "act_2",
          title: "Inspect soybean leaves for yellow mosaic spots",
          tag: "🌱 Crop Health",
          actionType: "inspect_leaves",
          completed: false,
        ),
        TodayActionModel(
          id: "act_3",
          title: "Upload weekly farm observation photo",
          tag: "📷 Observation",
          actionType: "photo_observation",
          completed: false,
        ),
      ],
      completedTasks: 1,
      totalTasks: 3,
      progressPercentage: 33,
    );
    state = state.copyWith(status: HomeStatus.loaded, dashboard: fallback);
  }
}

final homeProvider = StateNotifierProvider<HomeNotifier, HomeState>((ref) {
  final client = ref.watch(apiClientProvider);
  return HomeNotifier(client);
});
