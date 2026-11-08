# Minggu 11 — Optimasi Performa

Deliverable Minggu 11 untuk
[`radit-firansah-mobile-course`](https://github.com/Raditfiransah/radit-firansah-mobile-course).
Bukan project baru: ini project Minggu 10 (offline-first notes + cache-first posts +
AI chat) yang dioptimalkan, sesuai codelab
[11 | Optimasi Performa](https://jti-polinema.github.io/flutter-codelab/11-minggu-11-performance-optimization/index.html).

## Optimasi yang diterapkan

| # | Teknik | Lokasi | Efek |
| :-: | :--- | :--- | :--- |
| 1 | `const` constructor pada widget statis | `lib/pages/home_page.dart` | widget statis tidak dibangun ulang |
| 2 | Ekstrak widget (`_PostTile`) | `lib/pages/home_page.dart` | item list jadi unit rebuild sendiri |
| 3 | `RepaintBoundary` per item list | `lib/pages/home_page.dart` | paint terisolasi, scroll lebih mulus |
| 4 | Riverpod `select` | `lib/pages/home_page.dart` | badge dirty tidak me-rebuild seluruh halaman |
| 5 | Pagination / infinite scroll | `lib/pages/home_page.dart` | hanya 10 item yang di-layout, sisanya saat scroll |
| 6 | `dispose()` controller | `lib/pages/home_page.dart` | mencegah memory leak |

`ListView.builder` sudah dipakai sejak Minggu 5 dan dipertahankan. Optimasi gambar
tidak relevan karena aplikasi tidak memuat gambar dari jaringan.

## Struktur

```
11-week-11-performance-optimization/
├── lib/                      # project utuh (hasil optimasi)
├── docs/
│   ├── performance-findings.md   # temuan profiling + bukti di kode
│   └── performance-report.md     # baseline vs after, trade-off, refleksi
├── screenshots/              # before-profile.png / after-profile.png
└── test/                     # test Minggu 10, tetap lulus
```

## Cara menjalankan

```bash
cd 11-week-11-performance-optimization
flutter pub get
flutter run                # atau: flutter run -d chrome
```

Profiling:

```bash
flutter run --profile
# buka DevTools → Performance → Record → skenario: daftar, scroll cepat,
# detail, kembali, pull-to-refresh → Stop
```

## Status

`flutter analyze` bersih dan `flutter test` lulus. Screenshot profiling
(`screenshots/before-profile.png`, `after-profile.png`) dan angka metrik di
`docs/performance-report.md` diisi dari sesi `--profile` di perangkat/emulator.
