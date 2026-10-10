import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/core/format.dart';

void main() {
  test('formatShortDateTime memformat dua digit jam/menit', () {
    final dt = DateTime(2026, 9, 27, 9, 5);
    expect(formatShortDateTime(dt), '09:05 · 27/9/2026');
  });

  test('formatFullDateTime mengembalikan representasi lokal', () {
    final dt = DateTime(2026, 9, 27, 9, 5);
    expect(formatFullDateTime(dt), dt.toLocal().toString());
  });

  test('parseRouteId mengembalikan fallback untuk input invalid', () {
    expect(parseRouteId('42'), 42);
    expect(parseRouteId(null), 0);
    expect(parseRouteId('abc'), 0);
    expect(parseRouteId('abc', fallback: -1), -1);
  });
}
