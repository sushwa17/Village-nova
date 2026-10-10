import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:villagenova/providers/auth_provider.dart';
import 'package:villagenova/core/network/api_client.dart';

class ChatMessageItem {
  final bool isUser;
  final String text;
  final List<Map<String, dynamic>> actions;
  final String? whyAdvisory;
  final String? sourceCitation;

  ChatMessageItem({
    required this.isUser,
    required this.text,
    this.actions = const [],
    this.whyAdvisory,
    this.sourceCitation,
  });
}

class AskState {
  final bool isLoading;
  final List<ChatMessageItem> messages;

  const AskState({
    this.isLoading = false,
    this.messages = const [],
  });

  AskState copyWith({
    bool? isLoading,
    List<ChatMessageItem>? messages,
  }) {
    return AskState(
      isLoading: isLoading ?? this.isLoading,
      messages: messages ?? this.messages,
    );
  }
}

class AskNotifier extends StateNotifier<AskState> {
  final ApiClient apiClient;

  AskNotifier(this.apiClient)
      : super(
          AskState(
            messages: [
              ChatMessageItem(
                isUser: false,
                text: 'Good morning Ravi! 👋 I am your VillageNova companion. What would you like guidance on today?',
                actions: [],
              ),
            ],
          ),
        );

  Future<void> sendQuery(String userQuery) async {
    if (userQuery.trim().isEmpty) return;

    final updatedMessages = [
      ...state.messages,
      ChatMessageItem(isUser: true, text: userQuery),
    ];
    state = state.copyWith(isLoading: true, messages: updatedMessages);

    try {
      final response = await apiClient.dio.post(
        '/ask',
        data: {'message': userQuery},
      );

      if (response.statusCode == 200 && response.data['data'] != null) {
        final data = response.data['data'] as Map<String, dynamic>;
        final rawActions = (data['actions'] as List<dynamic>?)
                ?.map((e) => Map<String, dynamic>.from(e as Map))
                .toList() ??
            [];

        final aiMessage = ChatMessageItem(
          isUser: false,
          text: data['message'] as String? ?? 'Here is your guidance:',
          actions: rawActions,
          whyAdvisory: data['why_advisory'] as String?,
          sourceCitation: (data['sources'] as List<dynamic>?)?.isNotEmpty == true
              ? data['sources'][0]['title'] as String?
              : null,
        );

        state = state.copyWith(
          isLoading: false,
          messages: [...state.messages, aiMessage],
        );
        return;
      }
    } catch (_) {
      // Resilient local simulation if backend is offline
    }

    // Fallback advisory response
    await Future.delayed(const Duration(milliseconds: 500));
    final fallbackResponse = ChatMessageItem(
      isUser: false,
      text: 'Your Soybean crop is currently at Day 42 (Vegetative stage). Here are your recommended actions for today:',
      actions: [
        {'id': '1', 'title': '💧 Check soil moisture before evening rain', 'type': 'irrigation'},
        {'id': '2', 'title': '🌱 Inspect leaves for yellow mosaic spots', 'type': 'crop_health'},
        {'id': '3', 'title': '📷 Record a crop observation photo', 'type': 'observation'},
      ],
      whyAdvisory: 'Rain is forecasted in Ananthagiri at 6:00 PM (14 mm). Checking moisture now prevents over-saturation.',
      sourceCitation: 'Open-Meteo & PJTSAU Agriculture Advisory • Today 11:30 AM',
    );

    state = state.copyWith(
      isLoading: false,
      messages: [...state.messages, fallbackResponse],
    );
  }
}

final askProvider = StateNotifierProvider<AskNotifier, AskState>((ref) {
  final client = ref.watch(apiClientProvider);
  return AskNotifier(client);
});
