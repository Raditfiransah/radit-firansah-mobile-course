import '../../../../core/failures.dart';

abstract class PrefsRepository {
  Future<({bool value, Failure? failure})> getDarkMode();
  Future<Failure?> setDarkMode(bool value);
  Future<Failure?> markOpenedNow();
  Future<({String? value, Failure? failure})> getLastOpened();
}
