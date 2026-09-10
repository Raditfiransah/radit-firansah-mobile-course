import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:new_app/providers/stats_provider.dart';

void main() {
  group('StatsNotifier Unit Tests', () {
    // TEST 1: Pengujian State Sukses
    test('Mengembalikan 3 item data statistik saat pengambilan data berhasil', () async {
      final container = ProviderContainer(
        overrides: [
          statsProvider.overrideWith(
            () => StatsNotifier(delay: Duration.zero, failureRate: 0.0),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Membaca future hasil dari provider
      final stats = await container.read(statsProvider.future);

      expect(stats, isA<List<String>>());
      expect(stats.length, equals(3));
      expect(stats[0], equals('Total Pengguna: 1,250'));
      expect(stats[1], equals('Tugas Selesai: 85%'));
      expect(stats[2], equals('Waktu Aktif: 120 Jam'));
    });

    // TEST 2: Pengujian State Error
    test('Melempar Exception dan menghasilkan state error saat pengambilan data gagal', () async {
      final container = ProviderContainer(
        overrides: [
          statsProvider.overrideWith(
            () => StatsNotifier(delay: Duration.zero, failureRate: 1.0),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Inisialisasi pembacaan provider (AsyncLoading)
      final initial = container.read(statsProvider);
      expect(initial, isA<AsyncLoading>());

      // Tunggu hingga proses asinkron build() selesai melempar exception
      await Future<void>.delayed(Duration.zero);

      // Verifikasi bahwa state berubah menjadi AsyncError yang mengandung Exception
      final state = container.read(statsProvider);
      expect(state.hasError, isTrue);
      expect(state.error, isA<Exception>());
    });

    // TEST 3: Pengujian Method refresh()
    test('Method refresh() dapat memperbarui state data statistik', () async {
      final container = ProviderContainer(
        overrides: [
          statsProvider.overrideWith(
            () => StatsNotifier(delay: Duration.zero, failureRate: 0.0),
          ),
        ],
      );
      addTearDown(container.dispose);

      // Memastikan data awal dimuat terlebih dahulu
      await container.read(statsProvider.future);

      // Memanggil method refresh() dari notifier
      final notifier = container.read(statsProvider.notifier);
      await notifier.refresh();

      // Verifikasi bahwa state ter-refresh dan mengandung nilai
      final updatedState = container.read(statsProvider);
      expect(updatedState.hasValue, isTrue);
      expect(updatedState.value, contains('Total Pengguna: 1,250'));
    });
  });
}
