import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_key_store.dart';
import 'rate_limiter.dart';

class AiException implements Exception {
  const AiException(this.message);

  final String message;

  @override
  String toString() => message;
}

class ChatMessage {
  const ChatMessage({required this.role, required this.text});

  final String role; // 'user' | 'model'
  final String text;

  Map<String, Object?> toJson() => {
    'role': role,
    'parts': [
      {'text': text},
    ],
  };
}

class AiService {
  AiService({
    required this.keyStore,
    http.Client? client,
    RateLimiter? rateLimiter,
    this.model = 'gemini-2.5-flash',
  }) : _client = client ?? http.Client(),
       _rateLimiter = rateLimiter ?? RateLimiter();

  static const systemPrompt =
      'Kamu asisten kampus yang ramah. Jawab dalam Bahasa Indonesia, '
      'maksimal 2 kalimat, dan langsung ke inti. Jangan pernah meminta, '
      'mengulang, atau menyimpan NIK, nomor telepon, alamat, atau data '
      'pribadi pengguna.';

  final ApiKeyStore keyStore;
  final http.Client _client;
  final RateLimiter _rateLimiter;
  final String model;

  Future<bool> hasApiKey() async {
    final key = await keyStore.read();
    return key != null && key.trim().isNotEmpty;
  }

  Future<void> saveApiKey(String key) => keyStore.write(key);

  Future<void> clearApiKey() => keyStore.clear();

  Stream<String> askStream(
    String question, {
    List<ChatMessage> history = const [],
  }) async* {
    final apiKey = (await keyStore.read())?.trim();
    if (apiKey == null || apiKey.isEmpty) {
      throw const AiException(
        'API key belum diatur. Buka Pengaturan lalu simpan API key Gemini.',
      );
    }

    await _rateLimiter.consume();

    final request = http.Request(
      'POST',
      Uri.https(
        'generativelanguage.googleapis.com',
        '/v1beta/models/$model:streamGenerateContent',
        {'alt': 'sse', 'key': apiKey},
      ),
    );
    request.headers['Content-Type'] = 'application/json';
    request.body = jsonEncode({
      'systemInstruction': {
        'parts': [
          {'text': systemPrompt},
        ],
      },
      'contents': [
        ...history.map((m) => m.toJson()),
        ChatMessage(role: 'user', text: question).toJson(),
      ],
      'generationConfig': {'temperature': 0.4, 'maxOutputTokens': 512},
    });

    final http.StreamedResponse response;
    try {
      response = await _client
          .send(request)
          .timeout(const Duration(seconds: 30));
    } on SocketException {
      throw const AiException(
        'Tidak ada koneksi internet. Coba lagi saat online.',
      );
    } on http.ClientException {
      throw const AiException(
        'Gagal menghubungi layanan AI. Periksa koneksi lalu coba lagi.',
      );
    } on TimeoutException {
      throw const AiException('Layanan AI tidak merespons. Coba lagi nanti.');
    }

    if (response.statusCode != 200) {
      final body = await response.stream.bytesToString();
      throw AiException(_friendlyError(response.statusCode, body));
    }

    await for (final line
        in response.stream
            .transform(utf8.decoder)
            .transform(const LineSplitter())) {
      final chunk = parseSseLine(line);
      if (chunk != null && chunk.isNotEmpty) yield chunk;
    }
  }

  // Satu baris SSE Gemini: `data: {"candidates":[{"content":{"parts":[...]}}]}`
  static String? parseSseLine(String line) {
    if (!line.startsWith('data:')) return null;
    final data = line.substring(5).trim();
    if (data.isEmpty || data == '[DONE]') return null;

    try {
      final json = jsonDecode(data);
      if (json is! Map<String, dynamic>) return null;
      final candidates = json['candidates'];
      if (candidates is! List || candidates.isEmpty) return null;
      final content = (candidates.first as Map)['content'];
      if (content is! Map) return null;
      final parts = content['parts'];
      if (parts is! List) return null;
      return parts
          .whereType<Map>()
          .map((part) => part['text'])
          .whereType<String>()
          .join();
    } on FormatException {
      return null;
    }
  }

  static String _friendlyError(int statusCode, String body) {
    if (statusCode == 400 || statusCode == 403) {
      return 'API key ditolak. Periksa kembali key Gemini di Pengaturan.';
    }
    if (statusCode == 429) {
      return 'Kuota AI API habis atau terlalu banyak permintaan. '
          'Coba lagi nanti.';
    }
    if (statusCode >= 500) {
      return 'Layanan AI sedang sibuk. Coba lagi beberapa saat.';
    }
    return 'Gagal memanggil AI API ($statusCode).';
  }
}
