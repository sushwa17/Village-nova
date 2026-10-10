import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/models/resident_model.dart';
import 'package:villagenova/core/network/api_client.dart';

enum AuthStatus { unauthenticated, loading, authenticated, error }

class AuthState {
  final AuthStatus status;
  final ResidentProfileModel? resident;
  final String? errorMessage;
  final String? phoneNumber;

  const AuthState({
    this.status = AuthStatus.unauthenticated,
    this.resident,
    this.errorMessage,
    this.phoneNumber,
  });

  AuthState copyWith({
    AuthStatus? status,
    ResidentProfileModel? resident,
    String? errorMessage,
    String? phoneNumber,
  }) {
    return AuthState(
      status: status ?? this.status,
      resident: resident ?? this.resident,
      errorMessage: errorMessage ?? this.errorMessage,
      phoneNumber: phoneNumber ?? this.phoneNumber,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final ApiClient apiClient;

  AuthNotifier(this.apiClient) : super(const AuthState());

  Future<void> sendOtp(String phone) async {
    state = state.copyWith(status: AuthStatus.loading, phoneNumber: phone);
    try {
      // In production: Supabase.instance.client.auth.signInWithOtp(phone: phone);
      await Future.delayed(const Duration(milliseconds: 600));
      state = state.copyWith(status: AuthStatus.unauthenticated);
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  Future<void> verifyOtp(String otp) async {
    state = state.copyWith(status: AuthStatus.loading);
    try {
      // In production: Supabase.instance.client.auth.verifyOTP(...);
      await Future.delayed(const Duration(milliseconds: 600));
      final defaultProfile = ResidentProfileModel(
        id: 'user_001',
        fullName: 'Ravi Kumar',
        phoneNumber: state.phoneNumber ?? '+919876543210',
        villageName: 'Ananthagiri',
        preferredLanguage: 'te',
        roles: ['farmer'],
      );
      state = state.copyWith(
        status: AuthStatus.authenticated,
        resident: defaultProfile,
      );
    } catch (e) {
      state = state.copyWith(status: AuthStatus.error, errorMessage: e.toString());
    }
  }

  void signOut() {
    state = const AuthState(status: AuthStatus.unauthenticated);
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AuthNotifier(client);
});
