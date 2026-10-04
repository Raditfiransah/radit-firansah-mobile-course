# Checklist Verifikasi AI

| Pertanyaan verifikasi | Status | Temuan |
|-----------------------|--------|--------|
| Background handler top-level + `@pragma('vm:entry-point')`? | LULUS | `firebaseMessagingBackgroundHandler` top-level, bukan method kelas (`push_service.dart:46`) |
| `onTokenRefresh` benar-benar kirim token ke backend? | LULUS | Callback `onToken` sama dengan `getToken`, memanggil `POST /devices` (`main.dart:55`) |
| Foreground pakai local notification manual? | LULUS | `_local.show` di `listenForeground` (`push_service.dart:76`) |
| Klik 3 state masuk rute benar? | MENUNGGU | Perlu eksekusi uji nyata (lihat `05-tabel-hasil-uji.md`) |
| Token/secret tidak hardcode & tidak di-log penuh? | LULUS | Tidak ada token di kode; tidak ada `print` token. `google-services.json` berisi API key publik client (aman, bukan secret server) |

Catatan: `google-services.json` memang berisi `current_key` (API key Android).
Itu kunci client-side yang wajar ada di APK, bukan service-account secret.
Jangan commit service account JSON atau server key ke repo.
