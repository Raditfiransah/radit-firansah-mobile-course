# Temuan Profiling — Minggu 11

Project: `week11_performance_notes` (lanjutan project Minggu 10: offline-first notes +
cache-first posts + AI chat). Skenario profiling: buka daftar → scroll cepat → buka
detail → kembali → pull-to-refresh, dijalankan dengan `flutter run --profile`.

## Metode

1. `flutter run --profile`, buka DevTools → **Performance** → **Record**.
2. Jalankan skenario di atas, **Stop**, lalu baca frame chart (hijau < 16 ms, kuning
   16–32 ms, merah > 32 ms) dan Flame Chart (track UI Thread & Raster Thread).
3. Tab **Memory**: Heap Snapshot di halaman daftar → navigasi detail → kembali 5x →
   snapshot lagi → bandingkan jumlah instance.

## Temuan

| # | Temuan | Bukti di kode | Dampak | Perbaikan |
| :-: | :--- | :--- | :--- | :--- |
| 1 | Item list dibangun ulang bersama parent dan ikut di-repaint saat tetangganya berubah | `_NotesView` dan `_PostsView` di `lib/pages/home_page.dart` memakai `NoteTile`/`ListTile` langsung di `itemBuilder` | frame kuning saat scroll cepat | `RepaintBoundary` per item + item jadi widget `const` terpisah (`_PostTile`) |
| 2 | `HomePage` me-rebuild seluruh Scaffold saat status dirty berubah, padahal hanya badge yang butuh nilainya | `ref.watch(dirtyCountProvider)` di `lib/pages/home_page.dart` | build ulang AppBar + NavigationBar + body | `ref.watch(dirtyCountProvider.select((v) => v.value ?? 0))` |
| 3 | Semua post hasil cache dibangun sekaligus | `ListView.builder` tanpa batas jumlah item di `_PostsView` | layout/paint membengkak saat data bertambah | pagination 10 item + auto-load saat scroll mendekati akhir |
| 4 | ScrollController tidak pernah dibuang (pola umum leak) | `_PostsView` baru memakai controller | listener menumpuk tiap halaman dibuka ulang | `dispose()` memanggil `_scrollController.dispose()` |
| 5 | Widget statis di dalam `build` dibuat ulang tiap frame | item AppBar/NavigationBar di `lib/pages/home_page.dart` | alokasi objek sia-sia | `const` pada widget yang tidak bergantung state |

Catatan: aplikasi tidak memakai `Image.network`, jadi optimasi gambar
(`CachedNetworkImage`, `memCacheWidth/Height`) tidak diterapkan — tidak ada masalah
yang bisa diperbaiki di sisi itu.

## Cara verifikasi

- Ulangi Langkah 1 dengan skenario identik, simpan `screenshots/before-profile.png`
  dan `screenshots/after-profile.png`.
- Bandingkan jumlah frame merah/kuning dan rata-rata frame time.
- Memory: snapshot sebelum/sesudah 5x navigasi bolak-balik; jumlah instance
  `_PostsViewState`/`ScrollController` tidak boleh bertambah.
