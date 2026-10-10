# AI Challenge — Minggu 7: Clean Architecture

Dokumen ini memenuhi bagian **AI Challenge** pada codelab Minggu 7. Isinya:
prompt yang diberikan ke AI, output awal (usulan) AI, tabel
**usulan-vs-keputusan-final**, **AI Verification Checklist**, dan hasil tiga grep
verifikasi dependency rule.

Mengacu pada Praktikum 1–3 yang sudah dikerjakan pada project `week5_offline_notes`
(offline-first notes + cache-first API posts + settings). Refactor yang benar-benar
dilakukan baru mencakup **fitur notes** end-to-end; fitur posts & settings masih
struktur lama (scope Refactoring Challenge).

---

## 1. AI Prompt Challenge

### 1.1 Prompt asli codelab (rujukan)

> Project Flutter saya: campus_notify (auth + FCM + daftar pengumuman).
> Kondisi kini: folder lib/{data, providers, pages, messaging},
> repository tercampur dengan implementasi, widget memanggil Dio langsung.
> Tugas:
> 1. Usulkan struktur feature-first Clean Architecture
>    (presentation/domain/data) untuk fitur auth + announcements.
> 2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
> 3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
>    dan kapan use case benar-benar dibutuhkan vs repository langsung.
> 4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
> Jelaskan trade-off setiap keputusan.

### 1.2 Prompt yang dipakai (adaptasi ke project aktual)

Prompt asli menyasar `campus_notify` (Week 6). Karena project Minggu 7 ini adalah
`week5_offline_notes`, prompt diadaptasi ke fitur nyata (notes + posts + settings)
agar tabel usulan-vs-keputusan-final relevan dengan yang benar-benar direfactor.

```
Project Flutter saya: week5_offline_notes (offline-first notes + cache-first API posts + settings).
Kondisi kini: folder lib/{data, providers, pages, widgets, router},
repository tercampur dengan implementasi (interface & impl satu kelas),
entity dan mapping (toMap/fromMap/toJson) satu kelas,
widget/pages memakai entity dari layer data, dan wiring DI tersebar
(sebagian provider didefinisikan di dalam halaman presentation).
Fitur: (1) notes CRUD SQLite + flag dirty + sinkronisasi, (2) posts cache-first
(baca cache lalu refresh dari REST API Dio di background), (3) settings
(dark mode + last opened via shared_preferences).
Tugas:
1. Usulkan struktur feature-first Clean Architecture
   (presentation/domain/data) untuk fitur notes, posts, dan settings.
2. Untuk tiap file lama, sebutkan tujuan barunya (pindah/pecah/hapus).
3. Tandai bagian yang over-engineering bila diterapkan ke CRUD sederhana,
   dan kapan use case benar-benar dibutuhkan vs repository langsung.
4. Tunjukkan wiring DI dengan Riverpod (tanpa package DI tambahan).
Jelaskan trade-off setiap keputusan.
```

---

## 2. Output awal AI (usulan)

> Ringkasan usulan AI *sebelum* dinilai. Bagian yang ditolak/disempitkan
> dirinci di tabel §3.

### 2.1 Usulan struktur feature-first

```
lib/
├── core/
│   ├── failures.dart            # sealed Failure (murni Dart)
│   └── format.dart              # fungsi murni: format tanggal, parsing rute
├── features/
│   ├── notes/
│   │   ├── domain/
│   │   │   ├── entities/note.dart
│   │   │   ├── repositories/note_repository.dart      # interface
│   │   │   └── usecases/
│   │   │       ├── get_notes.dart
│   │   │       ├── add_note.dart
│   │   │       ├── delete_note.dart
│   │   │       ├── get_note_by_id.dart
│   │   │       └── sync_notes.dart
│   │   ├── data/
│   │   │   ├── models/note_model.dart                 # mapping hanya di sini
│   │   │   └── repositories/note_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/notes_providers.dart
│   │       ├── pages/notes_page.dart
│   │       ├── pages/note_detail_page.dart
│   │       └── widgets/note_tile.dart
│   ├── posts/
│   │   ├── domain/
│   │   │   ├── entities/post.dart
│   │   │   ├── repositories/post_repository.dart
│   │   │   └── usecases/load_posts_cache_first.dart
│   │   ├── data/
│   │   │   ├── models/post_model.dart
│   │   │   └── repositories/post_repository_impl.dart
│   │   └── presentation/providers/posts_providers.dart
│   └── settings/
│       ├── domain/repositories/prefs_repository.dart
│       ├── data/repositories/prefs_repository_impl.dart
│       └── presentation/
│           ├── providers/settings_providers.dart
│           └── pages/settings_page.dart
└── routes.dart                  # GoRouter + konstanta rute
```

### 2.2 Tujuan tiap file lama

| File lama | Usulan AI |
| :--- | :--- |
| `lib/data/local/note.dart` | Pecah → entity `domain/entities/note.dart` + model `data/models/note_model.dart`. |
| `lib/data/local/post.dart` | Pecah → entity `posts/domain/entities/post.dart` + model `data/models/post_model.dart`. |
| `lib/data/local/prefs.dart` | Pecah → interface `settings/domain/repositories/prefs_repository.dart` + impl `data/...`. |
| `lib/data/local/db.dart` | Pindah/pertahankan sebagai opener DB; disuntikkan ke repository impl (bukan diimpor widget). |
| `lib/data/repositories/note_repository.dart` | Pecah → interface di `domain` + impl di `data`. |
| `lib/data/repositories/post_repository.dart` | Pecah → interface di `domain` + impl di `data`. |
| `lib/data/sync.dart` | Pindah logika bisnis → use case (`SyncNotes`, `LoadPostsCacheFirst`). |
| `lib/providers/app_providers.dart` | Pecah → provider per fitur; `forceOfflineProvider` → `core/providers.dart`. |
| `lib/pages/home_page.dart` | Pecah → shell navigasi; daftar catatan → `notes/presentation/pages/notes_page.dart`. |
| `lib/pages/note_detail_page.dart` | Pindah → `notes/presentation/pages/`. |
| `lib/pages/settings_page.dart` | Pindah → `settings/presentation/pages/`; provider DI dikeluarkan. |
| `lib/widgets/note_tile.dart` | Pindah → `notes/presentation/widgets/`; impor entity domain. |
| `lib/router/app_router.dart` | Pindah → `lib/routes.dart`. |

### 2.3 Penanda over-engineering (versi AI)

- Use case per CRUD satu-baris (`AddNote`, `DeleteNote`, `GetNoteById`) → **berlebihan**;
  cukup repository langsung ke notifier.
- `core/format.dart` untuk satu-dua pemakaian → berlebihan bila hanya dipakai sekali.
- Interface repository untuk `PrefsRepository` (hanya 4 method skalar) → bisa
  dianggap berlebihan untuk project kecil.

### 2.4 Usulan wiring DI (Riverpod)

```dart
final noteRepositoryProvider = Provider<NoteRepository>(
  (ref) => NoteRepositoryImpl(openNotesDb),
);
final getNotesProvider = Provider<GetNotes>(
  (ref) => GetNotes(ref.watch(noteRepositoryProvider)),
);
final notesProvider = FutureProvider<List<Note>>((ref) async {
  final result = await ref.watch(getNotesProvider).call();
  if (result.failure != null) throw Exception(result.failure!.message);
  return result.notes;
});
```

### 2.5 Trade-off yang disebut AI

- **Lebih banyak file** demi arah dependensi yang benar → biaya navigasi, untung
  testabilitas & isolasi fitur.
- **Record `({T, Failure?})`** menghindari exception bocor tanpa menambah dependency
  (`fpdart`/`dartz`) → trade-off: tidak sekuat `Either` secara tipe.
- **Feature-first** lebih tahan tumbuh daripada layer-first, tapi lebih berat untuk
  project satu fitur.

---

## 3. Tabel usulan-vs-keputusan-final

> Catatan: keputusan di bawah diambil saat **Praktikum 3** (fokus notes). Beberapa
> item "Ditunda" (baris 7, 8, 10) **sudah dikerjakan** pada tahap Refactoring
> Challenge berikutnya — lihat bagian Refactoring Challenge di README.

| # | Usulan AI | Keputusan final | Alasan teknis |
| :-- | :--- | :--- | :--- |
| 1 | Entity `Note` di `domain`, mapping di `data` | **Diterima** | `Note` murni tanpa import Flutter; `toMap/fromMap/toEntity` hanya di `NoteModel`. |
| 2 | Interface repository di `domain`, impl di `data` | **Diterima** | `NoteRepository` (domain) ← `NoteRepositoryImpl` (data); presentation bergantung pada abstraksi. |
| 3 | Use case `GetNotes` | **Diterima** | Operasi baca utama; kontrak record + `Failure?`. |
| 4 | Use case `SyncNotes` | **Diterima** | Aturan bisnis >1 langkah: `countDirty` → simulasi upload → `markAllSynced`. |
| 5 | Use case `AddNote`, `DeleteNote`, `GetNoteById` (per CRUD) | **Ditolak (disederhanakan)** | Over-engineering: operasi satu-baris cukup repository → notifier. Sesuai catatan codelab. |
| 6 | `notesProvider` sebagai `FutureProvider` | **Diubah → `AsyncNotifier`** | UI butuh mutasi (`addNote`/`deleteNote`/`sync`), bukan hanya baca. |
| 7 | Refactor penuh `posts` + `settings` | **Ditunda** | Di luar scope Praktikum 3 (notes). Masuk Refactoring Challenge. |
| 8 | Ekstrak `core/format.dart` (format tanggal, parsing rute) | **Ditunda** | Refactoring Challenge; belum dikerjakan agar fokus notes. |
| 9 | DI dipusatkan di provider Riverpod | **Diterima** | `notes_providers.dart` jadi satu-satunya wiring notes; widget tak `new Repository()`. |
| 10 | `forceOfflineProvider` → `core/providers.dart` | **Ditunda** | Masih di `app_providers.dart`; dipindah saat refactor posts. |
| 11 | `NoteRepositoryImpl(openDb: openNotesDb)` (named) | **Diubah → posisional** | `NoteRepositoryImpl(this._openDb)` agar `prefer_initializing_formals` bersih di `flutter analyze`. |
| 12 | Record `({T, Failure?})` tanpa `fpdart` | **Diterima** | Sukses/gagal eksplisit, tanpa dependency tambahan. |

---

## 4. AI Verification Checklist

| # | Pertanyaan verifikasi | Temuan | Status |
| :-- | :--- | :--- | :--- |
| 1 | Interface repository di `domain`, impl di `data`? | `lib/features/notes/domain/repositories/note_repository.dart` (interface) vs `lib/features/notes/data/repositories/note_repository_impl.dart` (impl). | ✅ |
| 2 | `domain` bebas import Flutter/Dio/SQLite/Firebase? | Diperiksa dengan grep (bukan dibaca sekilas) → **0 hasil**. | ✅ |
| 3 | AI membuat use case untuk tiap CRUD satu-baris? | **Tidak.** Hanya `GetNotes` + `SyncNotes`. `addNote`/`deleteNote`/`fetchNoteById` langsung repository → notifier, dengan alasan tertulis (§3 baris 5). | ✅ (tidak over-engineering) |
| 4 | Entity bebas mapping (`toMap/fromMap/toJson` hanya di model)? | `Note` (entity) bersih; mapping hanya di `NoteModel`. | ✅ |
| 5 | DI terpusat di provider & widget tak `new Repository()`? | Notes: terpusat di `notes_providers.dart`. **Catatan:** `settings_page.dart` masih mendefinisikan `PrefsRepository()` dan `app_providers.dart` masih `PostRepository()` → scope posts/settings (belum direfactor). | ⚠️ (notes ✅, posts/settings ditunda) |
| 6 | Keputusan final berbeda dari AI + alasan? | Ya — baris 5, 6, 7, 8, 10, 11 di §3. | ✅ |

---

## 5. Hasil tiga grep verifikasi

```
# 1. Presentation steril dari data mentah
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" \
   lib/features/notes/presentation lib/pages
# → 0 hasil
```

```
# 2. Domain steril dari framework & package
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" \
   lib/features/notes/domain lib/core
# → 0 hasil
```

```
# 3. Audit DI bocor (Praktikum 1)
rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
# → 2 hasil:
#   lib/pages/settings_page.dart:6  final prefsRepositoryProvider = Provider((ref) => PrefsRepository());
#   lib/providers/app_providers.dart:7  final postRepositoryProvider = Provider((ref) => PostRepository());
```

```
flutter analyze   # → No issues found!
flutter test      # → 7 test lulus
```

Grep 1 & 2 (untuk fitur `notes`) **nol hasil** → dependency rule terbukti untuk
fitur yang direfactor. Grep 3 masih 2 hasil pada **posts/settings**, yang memang
belum masuk scope Praktikum 3 dan menjadi target Refactoring Challenge.

---

## 6. Kesimpulan & pembelajaran

- **Interface di `domain`, bukan `data`.** Jika dibalik, `domain` (logika bisnis)
  akan bergantung pada detail penyimpanan/transport; use case tak bisa diuji tanpa
  SQLite/Dio, dan arah dependensi terbalik (melanggar dependency rule).
- **Kapan use case perlu.** Saat operasi menggabungkan >1 langkah/repository atau
  punya aturan bisnis (mis. `SyncNotes`). CRUD satu-baris cukup repository → notifier.
- **Biaya over-engineering.** Use case per CRUD memperbanyak file & lapisan tanpa
  menambah nilai, memperlambat onboarding tim kecil. Sepadan hanya bila logika
  bisnis benar-benar tumbuh (validasi, sync, multi-sumber).
- **Bagian usulan AI yang ditolak/disempitkan.** Use case per CRUD (baris 5),
  refactor posts/settings sekaligus (baris 7), dan `core/format.dart` (baris 8) —
  ditunda/disederhanakan agar refactor bertahap dan tiap langkah terverifikasi.
- **Deviasi sadar dari contoh codelab.** `AsyncNotifier` (bukan `FutureProvider`)
  dan parameter impl posisional — keduanya didokumentasikan di README.
