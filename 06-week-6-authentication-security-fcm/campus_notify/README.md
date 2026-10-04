# Campus Notification App

Mini project: Flutter Campus Notification App dengan autentikasi, penyimpanan
token aman, refresh Dio otomatis, dan FCM (permission, token lifecycle,
notifikasi gabungan notification + data, deep link tiga app state).

## Fitur

- **Auth + guard route**: belum login selalu diarahkan ke `/login`
  (`lib/main.dart`), login mock siap diganti Firebase Auth
  (`lib/data/auth_repository.dart`).
- **Token aman**: disimpan di `flutter_secure_storage` via `lib/data/token_store.dart`.
- **Refresh otomatis**: Dio mencoba refresh **sekali** saat 401 lalu mengulang
  request; bila refresh mati sesi dibersihkan (logout)
  (`lib/data/api_client.dart`).
- **FCM**: permission, `getToken` + `onTokenRefresh` dikirim ke `POST /devices`,
  subscribe topik `pengumuman-kampus` (`lib/messaging/push_service.dart`).
- **Deep link tiga state**: foreground/background/terminated menuju
  `/pengumuman/:id`.
- **Halaman Debug**: menampilkan token FCM terpotong (`/debug`).

## Endpoint backend

Token perangkat dikirim ke:

```
POST /devices
{ "fcm_token": "<token>", "platform": "android" }
```

Base URL placeholder ada di `lib/data/api_client.dart`; ganti dengan API kampus.
Pesan backend memakai HTTP v1 dengan payload gabungan:

```json
{
  "message": {
    "topic": "pengumuman-kampus",
    "notification": {
      "title": "Jadwal kuliah berubah",
      "body": "Kelas Mobile pindah ke Ruang A2 jam 13.00"
    },
    "data": { "route": "/pengumuman/3", "id": "3" }
  }
}
```

## Tabel pengujian tiga app state

| State | Yang diharapkan | Cara uji | Hasil |
|-------|-----------------|----------|-------|
| Foreground | Banner lokal muncul, klik masuk `/pengumuman/3` | App terbuka, kirim dari console/backend | Menunggu kirim FCM |
| Background | Banner sistem muncul, klik masuk rute benar | Tekan Home, kirim, klik banner | Menunggu kirim FCM |
| Terminated | App terbuka ke rute benar via `getInitialMessage` | Swipe-close app, kirim, klik banner | Menunggu kirim FCM |

Bukti deep link yang sudah terverifikasi: `screenshots/deep-link-tujuan.png`
(rute `/pengumuman/3`). Detail status ada di `docs/05-tabel-hasil-uji.md`.

## Screenshots

| File | Isi |
|------|-----|
| `screenshots/debug-token-terpotong.png` | Token FCM ditampilkan terpotong (12 karakter) |
| `screenshots/deep-link-tujuan.png` | Halaman tujuan deep link `/pengumuman/3` |

Banner tiap state belum dapat diambil karena pengiriman FCM memerlukan
kredensial Firebase (login Console atau service account). Lihat catatan di
`docs/05-tabel-hasil-uji.md`.

## Test

```
flutter test
```

- `test/route_parsing_test.dart` — parsing route dari payload data.
- `test/session_refresh_test.dart` — logika sesi/refresh: refresh sekali,
  tidak berulang saat token hasil refresh ditolak, dan logout saat refresh mati.

## Dokumentasi AI Challenge

- `docs/01-prompt.md` — prompt AI
- `docs/02-output-awal-ai.md` — draf awal AI
- `docs/03-perbaikan-manual.md` — perbaikan manual
- `docs/04-checklist-verifikasi.md` — checklist verifikasi
- `docs/05-tabel-hasil-uji.md` — status uji tiga state
- `docs/06-refleksi.md` — refleksi
