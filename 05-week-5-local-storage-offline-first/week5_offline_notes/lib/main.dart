import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'data/local/prefs.dart';
import 'pages/settings_page.dart';
import 'router/app_router.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Catat waktu terakhir aplikasi dibuka
  final prefs = PrefsRepository();
  await prefs.markOpenedNow();

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
