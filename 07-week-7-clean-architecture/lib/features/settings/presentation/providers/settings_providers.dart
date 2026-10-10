import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/prefs_repository_impl.dart';
import '../../domain/repositories/prefs_repository.dart';

final prefsRepositoryProvider = Provider<PrefsRepository>((ref) {
  return PrefsRepositoryImpl();
});

final darkModeProvider =
    AsyncNotifierProvider<DarkModeNotifier, bool>(DarkModeNotifier.new);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() async {
    final result = await ref.watch(prefsRepositoryProvider).getDarkMode();
    if (result.failure != null) {
      throw Exception(result.failure!.message);
    }
    return result.value;
  }

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      final failure = await ref.read(prefsRepositoryProvider).setDarkMode(next);
      if (failure != null) {
        throw Exception(failure.message);
      }
      return next;
    });
  }
}

final lastOpenedProvider = FutureProvider<String?>((ref) async {
  final result = await ref.read(prefsRepositoryProvider).getLastOpened();
  return result.value;
});
