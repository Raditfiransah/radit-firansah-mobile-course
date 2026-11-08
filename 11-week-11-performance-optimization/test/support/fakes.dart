import 'dart:convert';

import 'package:week11_performance_notes/ai/ai_service.dart';
import 'package:week11_performance_notes/ai/api_key_store.dart';
import 'package:week11_performance_notes/ai/rate_limiter.dart';

class InMemoryKeyStore implements ApiKeyStore {
  InMemoryKeyStore([this.key]);

  String? key;

  @override
  Future<String?> read() async => key;

  @override
  Future<void> write(String value) async => key = value;

  @override
  Future<void> clear() async => key = null;
}

class NoLimit extends RateLimiter {
  @override
  Future<void> consume() async {}
}

class FakeAiService extends AiService {
  FakeAiService({this.reply = 'Halo dari AI.', this.error})
    : super(keyStore: InMemoryKeyStore('test-key'), rateLimiter: NoLimit());

  final String reply;
  final String? error;

  @override
  Stream<String> askStream(
    String question, {
    List<ChatMessage> history = const [],
  }) async* {
    if (error != null) throw AiException(error!);
    yield reply;
  }
}

String sse(String text) =>
    'data: ${jsonEncode({
      'candidates': [
        {
          'content': {
            'parts': [
              {'text': text},
            ],
          },
        },
      ],
    })}\n\n';
