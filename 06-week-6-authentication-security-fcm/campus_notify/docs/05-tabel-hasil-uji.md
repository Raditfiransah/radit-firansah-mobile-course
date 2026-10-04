# Tabel Hasil Uji Tiga App State

Payload uji (gabungan notification + data):

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

| State | Yang diharapkan | Cara uji | Hasil | Bukti |
|-------|-----------------|----------|-------|-------|
| Foreground | Banner lokal muncul, klik masuk `/pengumuman/3` | App terbuka, kirim dari console/backend | MENUNGGU KIRIM FCM | |
| Background | Banner sistem muncul, klik masuk rute benar | Tekan Home, kirim, klik banner | MENUNGGU KIRIM FCM | |
| Terminated | App terbuka ke rute benar via `getInitialMessage` | Swipe-close app, kirim, klik banner | MENUNGGU KIRIM FCM | |

Yang sudah terverifikasi tanpa kirim FCM:

- Navigasi deep link ke `/pengumuman/3` berfungsi
  (`screenshots/deep-link-tujuan.png`).
- Token FCM berhasil didapat dan tampil terpotong di halaman Debug
  (`screenshots/debug-token-terpotong.png`).
- Permission notifikasi granted di emulator (`POST_NOTIFICATIONS: granted=true`).

Status: **belum bisa mengirim** FCM karena pengiriman memerlukan kredensial
Firebase (login Firebase Console atau service account JSON untuk HTTP v1).
Emulator sudah siap (`emulator-5554`, API 37, Play Services aktif), app
ter-install, dan user sudah login.

Cara melengkapi:
1. Login Firebase Console di browser lalu kirim ke topik `pengumuman-kampus`, atau
2. Berikan service account JSON (Project settings -> Service accounts) untuk
   mengirim via HTTP v1.

Isi kolom Hasil dengan `LULUS`/`GAGAL` + catatan setelah pengujian, lalu simpan
screenshot banner tiap state di `screenshots/`.
