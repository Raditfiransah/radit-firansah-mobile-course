import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:week10_ai_notes/ai/ai_service.dart';
import 'package:week10_ai_notes/ai/rate_limiter.dart';

import 'support/fakes.dart';

void main() {
  test('parseSseLine mengambil teks dan mengabaikan baris lain', () {
    expect(AiService.parseSseLine(sse('Halo')), 'Halo');
    expect(AiService.parseSseLine('data: [DONE]'), isNull);
    expect(AiService.parseSseLine('event: ping'), isNull);
    expect(AiService.parseSseLine('data: {bukan json}'), isNull);
    expect(AiService.parseSseLine('data: {"usageMetadata":{}}'), isNull);
  });

  test('askStream menggabungkan chunk dan mengirim system prompt', () async {
    late String body;
    final client = MockClient((request) async {
      body = request.body;
      return http.Response('${sse('Jadwal ')}${sse('Senin 08.00.')}', 200);
    });

    final service = AiService(
      keyStore: InMemoryKeyStore('test-key'),
      client: client,
      rateLimiter: NoLimit(),
    );

    final chunks = await service.askStream('Jadwal Senin?').toList();
    expect(chunks, ['Jadwal ', 'Senin 08.00.']);

    final payload = jsonDecode(body) as Map<String, dynamic>;
    expect(payload['systemInstruction'], isNotNull);
    expect(payload['contents'], isNotEmpty);
  });

  test('askStream tanpa API key memberi pesan yang jelas', () async {
    final service = AiService(
      keyStore: InMemoryKeyStore(),
      client: MockClient((_) async => http.Response('', 200)),
      rateLimiter: NoLimit(),
    );

    await expectLater(
      service.askStream('Halo').toList(),
      throwsA(
        isA<AiException>().having(
          (e) => e.message,
          'message',
          contains('API key belum diatur'),
        ),
      ),
    );
  });

  test('status 429 dipetakan ke pesan kuota', () async {
    final service = AiService(
      keyStore: InMemoryKeyStore('test-key'),
      client: MockClient((_) async => http.Response('quota', 429)),
      rateLimiter: NoLimit(),
    );

    await expectLater(
      service.askStream('Halo').toList(),
      throwsA(
        isA<AiException>().having(
          (e) => e.message,
          'message',
          contains('Kuota'),
        ),
      ),
    );
  });

  test('RateLimiter menolak permintaan melebihi batas harian', () async {
    SharedPreferences.setMockInitialValues({});
    final limiter = RateLimiter(dailyLimit: 2);

    await limiter.consume();
    await limiter.consume();
    await expectLater(limiter.consume(), throwsA(isA<AiException>()));
  });
}
