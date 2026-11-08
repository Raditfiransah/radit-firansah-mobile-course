import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../ai/ai_service.dart';
import '../ai/api_key_store.dart';
import 'app_providers.dart';

final apiKeyStoreProvider = Provider<ApiKeyStore>(
  (ref) => const SecureApiKeyStore(),
);

final aiServiceProvider = Provider<AiService>(
  (ref) => AiService(keyStore: ref.watch(apiKeyStoreProvider)),
);

final chatProvider = NotifierProvider<ChatController, ChatState>(
  ChatController.new,
);

class ChatState {
  const ChatState({
    this.messages = const [],
    this.isSending = false,
    this.error,
  });

  final List<ChatMessage> messages;
  final bool isSending;
  final String? error;

  ChatState copyWith({
    List<ChatMessage>? messages,
    bool? isSending,
    String? error,
  }) {
    return ChatState(
      messages: messages ?? this.messages,
      isSending: isSending ?? this.isSending,
      error: error,
    );
  }
}

class ChatController extends Notifier<ChatState> {
  @override
  ChatState build() => const ChatState();

  Future<void> send(String text) async {
    final question = text.trim();
    if (question.isEmpty || state.isSending) return;
    await _ask(question, state.messages);
  }

  Future<void> retry() async {
    final messages = state.messages;
    final lastUser = messages.lastIndexWhere((m) => m.role == 'user');
    if (lastUser < 0) return;
    await _ask(messages[lastUser].text, messages.sublist(0, lastUser));
  }

  Future<void> _ask(String question, List<ChatMessage> history) async {
    if (ref.read(forceOfflineProvider)) {
      state = state.copyWith(
        error:
            'Mode offline aktif. Matikan Force Offline di Pengaturan '
            'atau gunakan catatan lokal.',
        isSending: false,
      );
      return;
    }

    final userMessage = ChatMessage(role: 'user', text: question);
    final base = [...history, userMessage];
    state = ChatState(messages: base, isSending: true);

    final service = ref.read(aiServiceProvider);
    final buffer = StringBuffer();

    try {
      await for (final chunk in service.askStream(question, history: history)) {
        buffer.write(chunk);
        state = ChatState(
          messages: [
            ...base,
            ChatMessage(role: 'model', text: buffer.toString()),
          ],
          isSending: true,
        );
      }

      if (buffer.isEmpty) {
        throw const AiException('AI tidak mengembalikan jawaban. Coba lagi.');
      }
      state = ChatState(
        messages: [
          ...base,
          ChatMessage(role: 'model', text: buffer.toString()),
        ],
      );
    } on AiException catch (e) {
      state = ChatState(messages: base, error: e.message);
    } catch (e) {
      state = ChatState(messages: base, error: 'Terjadi kesalahan: $e');
    }
  }
}
