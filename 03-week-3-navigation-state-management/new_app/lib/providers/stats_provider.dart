import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider global untuk menyediakan StatsNotifier dan mengelola state asinkronnya.
final statsProvider =
    AsyncNotifierProvider<StatsNotifier, List<String>>(StatsNotifier.new);

/// Notifier asinkron (AsyncNotifier) untuk mengelola logika bisnis dan state data statistik.
class StatsNotifier extends AsyncNotifier<List<String>> {
  // Instance generator acak untuk mensimulasikan probabilitas kegagalan
  final Random _random;

  // Durasi delay simulasi jaringan (secara default 2 detik)
  final Duration delay;

  // Tingkat kegagalan simulasi (0.3 berarti 30% peluang gagal)
  final double failureRate;

  /// Constructor opsional untuk memungkinkan injeksi dependency saat pengetesan (Unit Test)
  StatsNotifier({
    Random? random,
    this.delay = const Duration(seconds: 2),
    this.failureRate = 0.3,
  }) : _random = random ?? Random();

  /// Method `build` secara otomatis dieksekusi saat provider pertama kali di-watch/dibaca.
  /// Method ini mengembalikan Future data awal state.
  @override
  Future<List<String>> build() async {
    // Memuat simulasi delay jaringan selama 2 detik
    await Future.delayed(delay);
    return _fetchStatsData();
  }

  /// Method `refresh` dipanggil dari UI untuk me-load ulang data statistik.
  Future<void> refresh() async {
    // Set state menjadi loading terlebih dahulu
    state = const AsyncLoading();
    // AsyncValue.guard mengeksekusi _fetchStatsData, otomatis menangkap error jika throw Exception
    state = await AsyncValue.guard(() => _fetchStatsData());
  }

  /// Helper privat untuk mensimulasikan pencarian data dari server/API dengan simulasi error 30%.
  Future<List<String>> _fetchStatsData() async {
    // Jika angka acak kurang dari failureRate (30% peluang), lempar Exception
    if (_random.nextDouble() < failureRate) {
      throw Exception('Gagal terhubung ke server statistik (Err 500).');
    }

    // Jika sukses, kembalikan 3 item data statistik
    return const [
      'Total Pengguna: 1,250',
      'Tugas Selesai: 85%',
      'Waktu Aktif: 120 Jam',
    ];
  }
}
