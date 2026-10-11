import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/models/resident_model.dart';
import 'package:villagenova/core/network/api_client.dart';
import 'package:villagenova/providers/auth_provider.dart';
import 'package:villagenova/providers/home_provider.dart';

class OnboardingState {
  final List<String> availableVillages;
  final bool isLoadingVillages;
  final bool isSubmitting;
  final String? errorMessage;

  const OnboardingState({
    this.availableVillages = const [
      'Ananthagiri (Vikarabad)',
      'Dharur (Vikarabad)',
      'Kotepally (Vikarabad)',
      'Nawabpet (Vikarabad)',
      'Parigi (Vikarabad)',
      'Kondurg (Shadnagar)',
      'Other Village',
    ],
    this.isLoadingVillages = false,
    this.isSubmitting = false,
    this.errorMessage,
  });

  OnboardingState copyWith({
    List<String>? availableVillages,
    bool? isLoadingVillages,
    bool? isSubmitting,
    String? errorMessage,
  }) {
    return OnboardingState(
      availableVillages: availableVillages ?? this.availableVillages,
      isLoadingVillages: isLoadingVillages ?? this.isLoadingVillages,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class OnboardingNotifier extends StateNotifier<OnboardingState> {
  final ApiClient apiClient;
  final Ref ref;

  OnboardingNotifier(this.apiClient, this.ref) : super(const OnboardingState()) {
    fetchVillages();
  }

  Future<void> fetchVillages() async {
    state = state.copyWith(isLoadingVillages: true);
    try {
      final response = await apiClient.dio.get('/villages');
      if (response.statusCode == 200 && response.data['data'] != null) {
        final list = (response.data['data'] as List<dynamic>)
            .map((e) => "${e['name']} (${e['mandal'] ?? e['district'] ?? ''})".trim())
            .toList();
        if (list.isNotEmpty) {
          state = state.copyWith(
            availableVillages: [...list, 'Other Village'],
            isLoadingVillages: false,
          );
          return;
        }
      }
    } catch (_) {
      // Gracefully retain regional defaults
    }
    state = state.copyWith(isLoadingVillages: false);
  }

  Future<bool> submitOnboarding({
    required String fullName,
    required String villageName,
    required String preferredLanguage,
    required List<String> roles,
    double? farmLandAcres,
    String? soilType,
    String? waterSource,
    String? mainCrop,
    String? sowingDate,
  }) async {
    state = state.copyWith(isSubmitting: true, errorMessage: null);

    final payload = {
      'full_name': fullName,
      'village_name': villageName,
      'preferred_language': preferredLanguage,
      'roles': roles,
      if (roles.contains('farmer'))
        'farm': {
          'farm_name': '$fullName Main Farm',
          'land_acres': farmLandAcres ?? 2.5,
          'soil_type': soilType ?? 'black',
          'water_source': waterSource ?? 'borewell',
          'main_crop': mainCrop ?? 'Soybean',
          'sowing_date': sowingDate,
        },
    };

    try {
      final response = await apiClient.dio.post('/resident/onboarding', data: payload);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data['data'] as Map<String, dynamic>;
        final profile = ResidentProfileModel(
          id: data['id']?.toString() ?? 'user_001',
          fullName: data['full_name']?.toString() ?? fullName,
          phoneNumber: data['phone_number']?.toString() ?? '+919876543210',
          villageName: data['village_name']?.toString() ?? villageName,
          preferredLanguage: data['preferred_language']?.toString() ?? preferredLanguage,
          roles: (data['roles'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? roles,
        );

        ref.read(authProvider.notifier).setResidentProfile(profile);
        ref.read(homeProvider.notifier).fetchHomeDashboard();
        state = state.copyWith(isSubmitting: false);
        return true;
      }
    } catch (e) {
      // Offline fallback: save profile locally and update home state
      final offlineProfile = ResidentProfileModel(
        id: 'user_offline_001',
        fullName: fullName,
        phoneNumber: '+919876543210',
        villageName: villageName,
        preferredLanguage: preferredLanguage,
        roles: roles,
      );
      ref.read(authProvider.notifier).setResidentProfile(offlineProfile);
      ref.read(homeProvider.notifier).fetchHomeDashboard();
      state = state.copyWith(isSubmitting: false);
      return true;
    }

    state = state.copyWith(isSubmitting: false);
    return false;
  }
}

final onboardingProvider = StateNotifierProvider<OnboardingNotifier, OnboardingState>((ref) {
  final client = ref.watch(apiClientProvider);
  return OnboardingNotifier(client, ref);
});
