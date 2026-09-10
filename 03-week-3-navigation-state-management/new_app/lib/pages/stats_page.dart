import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/stats_provider.dart';

/// Halaman StatsPage yang menggunakan ConsumerWidget dari flutter_riverpod
/// untuk mendengarkan perubahan state dari statsProvider.
class StatsPage extends ConsumerWidget {
  const StatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // ref.watch mendengarkan perubahan AsyncValue dari statsProvider
    final statsAsync = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statistik Pengguna'),
        actions: [
          // Action button di AppBar untuk merefresh data secara manual
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Perbarui Data',
            onPressed: () => ref.read(statsProvider.notifier).refresh(),
          ),
        ],
      ),
      // statsAsync.when memetakan 3 kondisi state: loading, error, dan success (data)
      body: statsAsync.when(
        // 1. STATE LOADING: Ditampilkan saat proses pengambilan data berlangsung (delay 2 detik)
        loading: () => const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Memuat data statistik...'),
            ],
          ),
        ),

        // 2. STATE ERROR: Ditampilkan saat pengambilan data gagal (30% peluang error)
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 60),
                const SizedBox(height: 16),
                Text(
                  'Terjadi Kesalahan:\n$err',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 20),
                // Tombol 'Coba lagi' memicu ref.invalidate untuk menjalankan ulang build() pada provider
                FilledButton.icon(
                  onPressed: () => ref.invalidate(statsProvider),
                  icon: const Icon(Icons.refresh),
                  label: const Text('Coba lagi'),
                ),
              ],
            ),
          ),
        ),

        // 3. STATE SUCCESS: Ditampilkan saat data 3 item statistik berhasil dimuat
        data: (stats) => RefreshIndicator(
          onRefresh: () => ref.read(statsProvider.notifier).refresh(),
          child: ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: stats.length,
            itemBuilder: (context, index) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12.0),
                child: ListTile(
                  leading: const CircleAvatar(
                    child: Icon(Icons.analytics),
                  ),
                  title: Text(
                    stats[index],
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text('Metrik Statistik #${index + 1}'),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
