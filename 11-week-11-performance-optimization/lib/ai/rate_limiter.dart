import 'package:shared_preferences/shared_preferences.dart';

import 'ai_service.dart';

/// Batas permintaan AI per hari agar biaya tidak melonjak.
class RateLimiter {
  RateLimiter({this.dailyLimit = 20});

  final int dailyLimit;

  static const _countKey = 'ai_requests_count';
  static const _dateKey = 'ai_requests_date';

  Future<void> consume() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final storedDate = prefs.getString(_dateKey);
    var count = storedDate == today ? (prefs.getInt(_countKey) ?? 0) : 0;

    if (count >= dailyLimit) {
      throw AiException(
        'Batas $dailyLimit permintaan AI per hari sudah tercapai. '
        'Coba lagi besok.',
      );
    }

    count++;
    await prefs.setString(_dateKey, today);
    await prefs.setInt(_countKey, count);
  }
}
