import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'pages/stats_page.dart';
import 'pages/todo_page.dart';

/// Konfigurasi GoRouter dengan ShellRoute untuk navigasi bawah (NavigationBar)
final router = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) {
        return Scaffold(
          body: child,
          bottomNavigationBar: NavigationBar(
            selectedIndex: state.uri.path == '/stats' ? 1 : 0,
            onDestinationSelected: (index) {
              if (index == 0) {
                context.go('/');
              } else if (index == 1) {
                context.go('/stats');
              }
            },
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.check_box_outlined),
                selectedIcon: Icon(Icons.check_box),
                label: 'Tugas',
              ),
              NavigationDestination(
                icon: Icon(Icons.analytics_outlined),
                selectedIcon: Icon(Icons.analytics),
                label: 'Statistik',
              ),
            ],
          ),
        );
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const TodoPage(),
        ),
        GoRoute(
          path: '/stats',
          builder: (context, state) => const StatsPage(),
        ),
      ],
    ),
  ],
);

void main() => runApp(const ProviderScope(child: MyApp()));

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Week 3 - ToDo & Stats',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      routerConfig: router,
    );
  }
}