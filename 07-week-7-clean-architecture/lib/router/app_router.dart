import 'package:go_router/go_router.dart';
import '../core/format.dart';
import '../features/notes/presentation/pages/note_detail_page.dart';
import '../features/settings/presentation/pages/settings_page.dart';
import '../pages/home_page.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) => const HomePage(),
      routes: [
        GoRoute(
          path: 'note/:id',
          builder: (context, state) {
            final id = parseRouteId(state.pathParameters['id']);
            return NoteDetailPage(noteId: id);
          },
        ),
        GoRoute(
          path: 'settings',
          builder: (context, state) => const SettingsPage(),
        ),
      ],
    ),
  ],
);
