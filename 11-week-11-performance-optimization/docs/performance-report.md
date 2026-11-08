# Laporan Performa — Minggu 11

## Ringkasan

Empat optimasi diterapkan pada project Minggu 10 (`week11_performance_notes`).
Semua perubahan ada di UI layer; perilaku aplikasi tidak berubah.

| # | Optimasi | File | Alasan dipilih |
| :-: | :--- | :--- | :--- |
| 1 | `RepaintBoundary` + ekstrak `_PostTile` (`const` widget) | `lib/pages/home_page.dart` | item list paling sering repaint saat scroll; boundary mengisolasi paint per item |
| 2 | Riverpod `select` untuk `dirtyCountProvider` | `lib/pages/home_page.dart` | `HomePage` hanya butuh angka dirty, bukan seluruh `AsyncValue` |
| 3 | Pagination 10 item + auto-load saat scroll | `lib/pages/home_page.dart` | membatasi jumlah item yang di-layout/di-paint pada list panjang |
| 4 | `dispose()` ScrollController | `lib/pages/home_page.dart` | mencegah listener & controller menumpuk (memory leak) |

Tambahan kecil: `const` pada widget statis di AppBar/NavigationBar, dan
`ListView.builder` dipertahankan (bukan `ListView(children: ...)`).

## Baseline vs hasil

Skenario: buka daftar → scroll cepat → buka detail → kembali → pull-to-refresh,
`flutter run --profile`, DevTools Performance + Memory.

| Metrik | Before | After |
| :--- | :--- | :--- |
| Frame merah (> 32 ms) | _isi dari rekaman profiling_ | _isi dari rekaman profiling_ |
| Frame kuning (16–32 ms) | _isi dari rekaman profiling_ | _isi dari rekaman profiling_ |
| Rata-rata frame time | _isi dari rekaman profiling_ | _isi dari rekaman profiling_ |
| Instance `ScrollController` setelah 5x navigasi | _isi dari heap snapshot_ | _isi dari heap snapshot_ |

Screenshot: `screenshots/before-profile.png` dan `screenshots/after-profile.png`
(diambil dari perangkat/emulator saat menjalankan Langkah 1 dan Langkah 4 codelab).

> Angka metrik sengaja tidak dikarang: isi tabel di atas dari rekaman DevTools
> pada perangkat Anda. Yang bisa diverifikasi tanpa perangkat adalah perubahan
> kode dan kebersihan `flutter analyze` / `flutter test` (lihat bawah).

## Verifikasi statis

```bash
flutter analyze   # No issues found
flutter test      # semua test lulus
```

## Trade-off

- **Pagination**: menambah state (`_visibleCount`, `ScrollController`) dan satu
  titik bug potensial (load-more ganda). Untungnya biaya layout per frame turun.
- **`RepaintBoundary`**: satu layer GPU tambahan per item. Untuk 10–15 item masih
  murah; kalau list sangat pendek, boundary ini tidak berguna.
- **`select`**: kode sedikit lebih verbose, tapi rebuild jauh lebih sempit.

## Refleksi

- **Dampak terbesar**: `RepaintBoundary` per item + ekstraksi `_PostTile`; scroll
  list adalah interaksi paling sering, jadi pengaruhnya paling terasa.
- **Bukan placebo**: dibuktikan dengan rekaman DevTools skenario identik sebelum
  dan sesudah, bukan dari perasaan "lebih halus".
- **Premature optimization dihindari**: tidak menambah `cached_network_image`,
  isolate, atau `const` berlebihan karena aplikasi ini tidak memuat gambar
  jaringan dan komputasinya ringan.
