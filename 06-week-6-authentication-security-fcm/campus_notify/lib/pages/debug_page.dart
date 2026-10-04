import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../messaging/push_service.dart';

class DebugPage extends ConsumerWidget {
  const DebugPage({super.key});

  // Jangan pernah menampilkan token penuh. Cukup 12 karakter pertama.
  String _truncate(String? token) {
    if (token == null || token.isEmpty) return '(belum ada token)';
    return token.length <= 12 ? token : '${token.substring(0, 12)}...';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final token = ref.watch(fcmTokenProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Debug FCM')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Token FCM (terpotong)'),
            const SizedBox(height: 8),
            token.when(
              data: (t) => SelectableText(
                _truncate(t),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
              ),
              loading: () => const CircularProgressIndicator(),
              error: (e, _) => Text('Gagal: $e'),
            ),
            const SizedBox(height: 24),
            const Text('Deep link tertunda'),
            const SizedBox(height: 8),
            Text(pendingDeepLink ?? '-'),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => ref.invalidate(fcmTokenProvider),
              child: const Text('Muat ulang token'),
            ),
          ],
        ),
      ),
    );
  }
}
