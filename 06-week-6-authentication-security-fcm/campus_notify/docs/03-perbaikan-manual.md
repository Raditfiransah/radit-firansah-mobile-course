# Daftar Perbaikan Manual atas Draf AI

| # | Masalah pada draf AI | Perbaikan manual | Lokasi |
|---|----------------------|------------------|--------|
| 1 | Background handler method kelas | Jadikan fungsi top-level + `@pragma('vm:entry-point')` | `push_service.dart:46` |
| 2 | Token hanya di-log | Kirim via callback `onToken` ke `POST /devices` | `push_service.dart:57`, `main.dart:55` |
| 3 | `onTokenRefresh` hanya log | Listener memakai callback `onToken` yang sama | `push_service.dart:65` |
| 4 | Topik pakai spasi | Ganti jadi `pengumuman-kampus` | `push_service.dart:68` |
| 5 | Foreground tanpa banner | Tambah local notification manual via `_local.show` | `push_service.dart:76` |
| 6 | Tidak ada `getInitialMessage` | Tambah `handleTerminated` | `push_service.dart:100` |
| 7 | Tidak ada pemisahan platform | Tandai `[ANDROID]` / `[iOS]` pada izin, channel, banner | `push_service.dart` |
| 8 | Token di-log penuh | Token tidak pernah di-`print`; hanya dikirim ke backend | seluruh file |
| 9 | Navigasi butuh context di service | Service terima callback `go`, context tetap di widget | `main.dart:52` |
| 10 | Channel Android belum dibuat | `createNotificationChannel` (wajib Android 8+) | `push_service.dart:37` |

Keputusan teknis: background handler tetap top-level dan **tidak** melakukan
navigasi langsung. Navigasi dijalankan saat aplikasi dibuka (klik banner)
supaya tidak menyentuh `BuildContext` di isolate terpisah.
