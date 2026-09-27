import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/local/prefs.dart';
import '../providers/app_providers.dart';

final prefsRepositoryProvider = Provider((ref) => PrefsRepository());
final darkModeProvider = AsyncNotifierProvider<DarkModeNotifier, bool>(
  DarkModeNotifier.new,
);

class DarkModeNotifier extends AsyncNotifier<bool> {
  @override
  Future<bool> build() => ref.watch(prefsRepositoryProvider).getDarkMode();

  Future<void> toggle() async {
    final next = !(state.value ?? false);
    state = const AsyncLoading();
    state = await AsyncValue.guard(() async {
      await ref.read(prefsRepositoryProvider).setDarkMode(next);
      return next;
    });
  }
}

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider).value ?? false;
    final isOffline = ref.watch(forceOfflineProvider);
    final prefsRepo = ref.read(prefsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaturan & Simulasi'),
      ),
      body: ListView(
        children: [
          SwitchListTile(
            secondary: Icon(
              isOffline ? Icons.wifi_off : Icons.wifi,
              color: isOffline ? Colors.red : Colors.green,
            ),
            title: const Text('Force Offline Mode'),
            subtitle: Text(
              isOffline ? 'Simulasi offline aktif' : 'Tersambung ke jaringan',
            ),
            value: isOffline,
            onChanged: (val) {
              ref.read(forceOfflineProvider.notifier).setOffline(val);
            },
          ),
          const Divider(),
          SwitchListTile(
            secondary: const Icon(Icons.dark_mode),
            title: const Text('Dark Mode'),
            subtitle: const Text('Disimpan ke SharedPreferences'),
            value: isDarkMode,
            onChanged: (val) {
              ref.read(darkModeProvider.notifier).toggle();
            },
          ),
          const Divider(),
          FutureBuilder<String?>(
            future: prefsRepo.getLastOpened(),
            builder: (context, snapshot) {
              return ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Terakhir Dibuka'),
                subtitle: Text(snapshot.data ?? 'Belum tercatat'),
              );
            },
          ),
        ],
      ),
    );
  }
}
