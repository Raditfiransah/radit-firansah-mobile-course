import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/providers.dart';
import '../providers/settings_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider).value ?? false;
    final isOffline = ref.watch(forceOfflineProvider);
    final lastOpened = ref.watch(lastOpenedProvider);

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
          lastOpened.when(
            data: (value) => ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Terakhir Dibuka'),
              subtitle: Text(value ?? 'Belum tercatat'),
            ),
            loading: () => const ListTile(
              leading: Icon(Icons.access_time),
              title: Text('Terakhir Dibuka'),
              subtitle: Text('Memuat...'),
            ),
            error: (e, _) => ListTile(
              leading: const Icon(Icons.access_time),
              title: const Text('Terakhir Dibuka'),
              subtitle: Text('$e'),
            ),
          ),
        ],
      ),
    );
  }
}
