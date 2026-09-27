import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week5_offline_notes/main.dart';

void main() {
  testWidgets('OfflineFirstApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: OfflineFirstApp(),
      ),
    );

    expect(find.text('Offline-First Demo'), findsOneWidget);
  });
}
