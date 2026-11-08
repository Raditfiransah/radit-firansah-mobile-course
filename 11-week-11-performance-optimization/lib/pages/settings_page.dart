import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/local/prefs.dart';
import '../providers/ai_providers.dart';
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

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool? _hasApiKey;

  @override
  void initState() {
    super.initState();
    _refreshApiKeyStatus();
  }

  Future<void> _refreshApiKeyStatus() async {
    final hasKey = await ref.read(aiServiceProvider).hasApiKey();
    if (mounted) setState(() => _hasApiKey = hasKey);
  }

  Future<void> _editApiKey() async {
    final controller = TextEditingController();
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Key disimpan di secure storage perangkat, bukan di kode sumber.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              obscureText: true,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'API key',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              await ref.read(aiServiceProvider).clearApiKey();
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Hapus'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () async {
              final key = controller.text.trim();
              if (key.isEmpty) return;
              await ref.read(aiServiceProvider).saveApiKey(key);
              if (ctx.mounted) Navigator.pop(ctx, true);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    controller.dispose();

    if (saved == true) {
      await _refreshApiKeyStatus();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pengaturan API key diperbarui.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = ref.watch(darkModeProvider).value ?? false;
    final isOffline = ref.watch(forceOfflineProvider);
    final prefsRepo = ref.read(prefsRepositoryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Pengaturan & Simulasi')),
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
          ListTile(
            leading: const Icon(Icons.key),
            title: const Text('Gemini API Key'),
            subtitle: Text(switch (_hasApiKey) {
              null => 'Memeriksa...',
              true => 'Tersimpan di secure storage',
              false => 'Belum diatur — fitur AI nonaktif',
            }),
            trailing: const Icon(Icons.edit),
            onTap: _editApiKey,
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
