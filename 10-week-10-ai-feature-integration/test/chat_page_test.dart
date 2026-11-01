import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:week10_ai_notes/pages/chat_page.dart';
import 'package:week10_ai_notes/providers/ai_providers.dart';
import 'package:week10_ai_notes/providers/app_providers.dart';

import 'support/fakes.dart';

Widget wrap(FakeAiService service) {
  return ProviderScope(
    overrides: [aiServiceProvider.overrideWithValue(service)],
    child: const MaterialApp(home: ChatPage()),
  );
}

void main() {
  testWidgets('mengirim pertanyaan dan menampilkan jawaban AI', (tester) async {
    await tester.pumpWidget(wrap(FakeAiService(reply: 'Kuliah mulai 08.00.')));

    await tester.enterText(find.byType(TextField), 'Jadwal Senin?');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.text('Jadwal Senin?'), findsOneWidget);
    expect(find.text('Kuliah mulai 08.00.'), findsOneWidget);
  });

  testWidgets('error AI tampil sebagai banner dengan tombol coba lagi', (
    tester,
  ) async {
    await tester.pumpWidget(
      wrap(FakeAiService(error: 'Layanan AI sedang sibuk. Coba lagi nanti.')),
    );

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(
      find.text('Layanan AI sedang sibuk. Coba lagi nanti.'),
      findsOneWidget,
    );
    expect(find.text('Coba lagi'), findsOneWidget);
  });

  testWidgets('mode offline menolak permintaan tanpa memanggil AI', (
    tester,
  ) async {
    final service = FakeAiService(reply: 'tidak boleh tampil');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: ChatPage()),
      ),
    );

    final container = ProviderScope.containerOf(
      tester.element(find.byType(ChatPage)),
    );
    container.read(forceOfflineProvider.notifier).setOffline(true);
    await tester.pump();

    await tester.enterText(find.byType(TextField), 'Halo');
    await tester.tap(find.byTooltip('Kirim'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Mode offline aktif'), findsOneWidget);
    expect(find.text('tidak boleh tampil'), findsNothing);
  });
}
