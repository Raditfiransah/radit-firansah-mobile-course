import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'features/settings/data/repositories/prefs_repository_impl.dart';
import 'features/settings/presentation/providers/settings_providers.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Composition root: catat waktu terakhir aplikasi dibuka.
  await PrefsRepositoryImpl().markOpenedNow();

  runApp(
    const ProviderScope(
      child: OfflineFirstApp(),
    ),
  );
}

class OfflineFirstApp extends ConsumerWidget {
  const OfflineFirstApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDarkMode = ref.watch(darkModeProvider).value ?? false;

    return MaterialApp.router(
      title: 'Offline-First Notes',
      debugShowCheckedModeBanner: false,
      themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      routerConfig: appRouter,
    );
  }
}
