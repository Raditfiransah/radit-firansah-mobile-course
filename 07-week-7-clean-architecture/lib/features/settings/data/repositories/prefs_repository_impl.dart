import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/failures.dart';
import '../../domain/repositories/prefs_repository.dart';

class PrefsRepositoryImpl implements PrefsRepository {
  static const _darkModeKey = 'dark_mode';
  static const _lastOpenedKey = 'last_opened_at';

  @override
  Future<({bool value, Failure? failure})> getDarkMode() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (value: prefs.getBool(_darkModeKey) ?? false, failure: null);
    } catch (e) {
      return (value: false, failure: LocalFailure('Gagal membaca tema: $e'));
    }
  }

  @override
  Future<Failure?> setDarkMode(bool value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, value);
      return null;
    } catch (e) {
      return LocalFailure('Gagal menyimpan tema: $e');
    }
  }

  @override
  Future<Failure?> markOpenedNow() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastOpenedKey, DateTime.now().toIso8601String());
      return null;
    } catch (e) {
      return LocalFailure('Gagal mencatat waktu buka: $e');
    }
  }

  @override
  Future<({String? value, Failure? failure})> getLastOpened() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return (value: prefs.getString(_lastOpenedKey), failure: null);
    } catch (e) {
      return (
        value: null,
        failure: LocalFailure('Gagal membaca waktu buka: $e'),
      );
    }
  }
}
