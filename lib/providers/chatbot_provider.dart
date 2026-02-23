import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/index.dart';
import '../services/index.dart';

/// Chatbot service provider
final chatbotServiceProvider = Provider<ChatbotService>((ref) {
  return ChatbotService();
});

/// Chat history provider
final chatHistoryProvider = FutureProvider.family<List<ChatbotModel>, String>((
  ref,
  studentId,
) async {
  final service = ref.watch(chatbotServiceProvider);
  return await service.getChatHistory(studentId);
});

/// Chatbot message notifier provider
final chatbotMessageProvider =
    StateNotifierProvider<ChatbotMessageNotifier, AsyncValue<String?>>((ref) {
      return ChatbotMessageNotifier(ref.watch(chatbotServiceProvider));
    });

/// Chatbot message state notifier
class ChatbotMessageNotifier extends StateNotifier<AsyncValue<String?>> {
  final ChatbotService _service;

  ChatbotMessageNotifier(this._service) : super(const AsyncValue.data(null));

  /// Process user message and get response
  Future<void> sendMessage({
    required String studentId,
    required String message,
  }) async {
    state = const AsyncValue.loading();

    state = await AsyncValue.guard(() async {
      return await _service.processMessage(
        studentId: studentId,
        message: message,
      );
    });
  }

  /// Reset state
  void reset() {
    state = const AsyncValue.data(null);
  }
}
