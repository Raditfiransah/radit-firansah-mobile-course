# Minggu 7 — Clean Architecture

Refactor project Minggu 5 (`week5_offline_notes`, offline-first notes + cache-first
API posts) menjadi struktur **feature-first Clean Architecture**. Project ini
melanjutkan repository yang sama, bukan project baru.

> **Status:** Praktikum 1 (Audit) ✅, Praktikum 2 (Domain & data notes) ✅,
> Praktikum 3 (Presentation + DI + verifikasi, fitur notes) ✅. Fitur posts &
> settings masih struktur lama (scope Refactoring Challenge).

## Tujuan

- Memisahkan kode ke tiga layer (presentation, domain, data) per fitur.
- Menegakkan **dependency rule**: dependensi hanya mengarah ke dalam
  (`presentation → domain ← data`); `domain` bebas dari Flutter/Dio/SQLite.
- Memisahkan entity (murni) dari model (mapping), memindahkan kontrak repository
  ke `domain`, dan memusatkan wiring DI di provider Riverpod.

## Fitur utama (existing)

- **Catatan (Notes)** — CRUD SQLite lokal + flag `dirty` untuk antrean sinkronisasi.
- **Posts (Cache-First)** — baca cache SQLite lalu refresh dari REST API
  (JSONPlaceholder) di background.
- **Pengaturan** — dark mode + waktu terakhir dibuka via `shared_preferences`,
  toggle *Force Offline*.

## Stack teknologi

Flutter, `flutter_riverpod` (state + DI), `go_router` (navigasi), `sqflite` +
`sqflite_common_ffi` (SQLite lokal), `dio` (REST API), `shared_preferences`
(preferensi).

## Cara menjalankan

```bash
flutter pub get
flutter run            # desktop/web via sqflite_common_ffi
flutter analyze
flutter test
```

---

## Praktikum 1 — Audit layer project lama

### 1. Pemetaan file ke layer

| File | Layer saat ini | Masalah |
| :--- | :--- | :--- |
| `lib/main.dart` | presentation | `PrefsRepository()` diinstansiasi manual di `main()` (DI bocor); `darkModeProvider` diimpor dari `settings_page.dart`. |
| `lib/data/local/db.dart` | data | OK — hanya pembuka DB + skema, dipakai repository. |
| `lib/data/local/note.dart` | data (+ mapping tercampur) | Entity dan mapping (`toMap`/`fromMap`) masih satu kelas. |
| `lib/data/local/post.dart` | data (+ mapping tercampur) | Entity dan mapping (`toJson`/`fromJson`) masih satu kelas. |
| `lib/data/local/prefs.dart` | data | OK sebagai akses storage; provider-nya justru didefinisikan di presentation. |
| `lib/data/repositories/note_repository.dart` | data (+ kontrak tercampur) | Kelas konkret, tidak ada interface di `domain`; mengembalikan `List<Note>` & **melempar exception** (belum ada `Failure`). |
| `lib/data/repositories/post_repository.dart` | data (+ kontrak tercampur) | Kelas konkret; mencampur `Dio` + `sqflite`; melempar `Exception`. |
| `lib/data/sync.dart` | data (+ logika bisnis) | `syncNotes`, `loadPostsCacheFirst`, `refreshPostsInBackground` = aturan bisnis; seharusnya use case di `domain`. |
| `lib/pages/home_page.dart` | presentation | Bersih dari jaringan/DB langsung; hanya memanggil notifier. |
| `lib/pages/note_detail_page.dart` | presentation | Format tanggal mentah inline (`note.updatedAt.toLocal()`). |
| `lib/pages/settings_page.dart` | presentation | Mendefinisikan `prefsRepositoryProvider` + `darkModeProvider` (DI di presentation); import `data/local/prefs.dart`. |
| `lib/providers/app_providers.dart` | presentation (state) | Instansiasi konkret `NoteRepository()` / `PostRepository()`; memanggil logika `sync.dart`; import langsung ke `data`. |
| `lib/router/app_router.dart` | presentation | OK; parsing rute (`int.tryParse`) inline — kandidat ekstraksi ke `core/format.dart`. |
| `lib/widgets/note_tile.dart` | presentation | Formatting tanggal manual (`padLeft`) di dalam widget. |
| `test/note_test.dart` | test | Fake meng-*extends* `NoteRepository` konkret (belum implement interface domain). |
| `test/widget_test.dart` | test | Smoke test app. |

### 2. Tiga pelanggaran klasik (hasil grep)

```
# 1. Widget menyentuh jaringan / database langsung
rg "Dio\(|http\.|openDatabase|SharedPreferences\.getInstance|FlutterSecureStorage" lib/pages lib/widgets
```

**Hasil: 0 match.** Presentation sudah steril dari akses data mentah.

```
# 2. Logika bisnis di dalam build()
rg "DateFormat|jsonDecode|\.toIso8601String" lib/pages lib/widgets
```

**Hasil: 0 match.** Tidak ada parsing JSON / format tanggal mentah yang terdeteksi.
(Catatan: `note_tile.dart` & `note_detail_page.dart` tetap memformat tanggal secara
manual — tidak tertangkap pola ini, tapi tetap masuk daftar refactor ke `core/format.dart`.)

```
# 3. Instansiasi manual (DI bocor)
rg "Repository\(|Dio\(BaseOptions" lib/pages lib/providers
```

**Hasil: 3 match.**

| Lokasi | Temuan |
| :--- | :--- |
| `lib/pages/settings_page.dart:6` | `final prefsRepositoryProvider = Provider((ref) => PrefsRepository());` — provider data didefinisikan di presentation. |
| `lib/providers/app_providers.dart:9` | `final noteRepositoryProvider = Provider((ref) => NoteRepository());` — instansiasi konkret (belum lewat abstraksi). |
| `lib/providers/app_providers.dart:10` | `final postRepositoryProvider = Provider((ref) => PostRepository());` — instansiasi konkret. |

Grep 1 & 2 sudah nol; grep 3 menjadi item refactor utama Praktikum 3
(pusatkan wiring DI, definisikan interface di `domain`, provider per fitur).

### 3. Struktur target (feature-first)

```
lib/
├── core/
│   ├── failures.dart          # Failure domain (murni Dart)
│   ├── format.dart            # fungsi murni: format tanggal, parsing rute
│   └── providers.dart         # provider lintas fitur (forceOffline)
├── features/
│   ├── notes/
│   │   ├── domain/
│   │   │   ├── entities/note.dart
│   │   │   ├── repositories/note_repository.dart      # interface!
│   │   │   └── usecases/{get_notes,add_note,delete_note,sync_notes}.dart
│   │   ├── data/
│   │   │   ├── models/note_model.dart                 # mapping hanya di sini
│   │   │   └── repositories/note_repository_impl.dart
│   │   └── presentation/
│   │       ├── providers/notes_providers.dart         # notifier + DI
│   │       └── pages/note_detail_page.dart
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
│       ├── domain/repositories/prefs_repository.dart  # interface
│       ├── data/repositories/prefs_repository_impl.dart
│       └── presentation/
│           ├── providers/settings_providers.dart
│           └── pages/settings_page.dart
└── routes.dart                # GoRouter + konstanta rute
```

### Diagram layer dan arah dependensi

```
presentation (widget, notifier, router)
      |
      v  bergantung ke
domain (entity, repository interface, use case, failure)
      ^
      |  diimplementasikan oleh
data (model, repository impl, Dio, SQLite, secure storage)
```

Aturan emas: dependensi hanya mengarah ke dalam. `domain` tidak tahu apa pun
tentang Flutter, Dio, atau SQLite — sehingga logika bisnis dapat diunit-test murni.
Fitur berkomunikasi via rute, bukan saling mengimpor widget.

## Praktikum 2 — Domain dan data per fitur (notes)

File baru (fitur `notes`), mengikuti codelab. File lama **tidak dihapus** agar
aplikasi tetap berjalan; rewiring dikerjakan di Praktikum 3.

| File | Layer | Isi |
| :--- | :--- | :--- |
| `lib/core/failures.dart` | core | `sealed Failure` + `LocalFailure` + `NetworkFailure` (murni Dart). |
| `lib/features/notes/domain/entities/note.dart` | domain | Entity `Note` murni, tanpa import Flutter & tanpa mapping. |
| `lib/features/notes/domain/repositories/note_repository.dart` | domain | Interface kontrak (`fetchNotes`, `addNote`) memakai record `({..., Failure? failure})`. |
| `lib/features/notes/domain/usecases/get_notes.dart` | domain | Use case `GetNotes` (menerima abstraksi `NoteRepository`). |
| `lib/features/notes/data/models/note_model.dart` | data | `NoteModel extends Note`; mapping `toMap`/`fromMap`/`toEntity` **hanya di sini**. |
| `lib/features/notes/data/repositories/note_repository_impl.dart` | data | `NoteRepositoryImpl implements NoteRepository`; exception dibungkus jadi `LocalFailure`. |
| `test/get_notes_test.dart` | test | 2 test use case dengan `FakeNoteRepository` (sukses + failure), tanpa SQLite/Dio. |

Catatan: kontrak interface sengaja **minimal** (persis codelab). Method lama
(`fetchNoteById`, `deleteNote`, `countDirty`, `markAllSynced`) akan ditambahkan
saat rewiring provider di Praktikum 3. `NoteRepositoryImpl` memakai
*initializing formal* posisional (`NoteRepositoryImpl(this._openDb)`) agar
`flutter analyze` bersih.

## Praktikum 3 — Presentation, DI, dan verifikasi (notes)

Fitur `notes` disambungkan end-to-end; file lama untuk notes dihapus.

**File baru / pindah**

| File | Isi |
| :--- | :--- |
| `lib/features/notes/domain/usecases/sync_notes.dart` | Use case `SyncNotes`: `countDirty` → (simulasi upload) → `markAllSynced`. |
| `lib/features/notes/presentation/providers/notes_providers.dart` | DI Riverpod: `noteRepositoryProvider`, `getNotesProvider`, `syncNotesProvider`, `notesProvider` (AsyncNotifier), `dirtyCountProvider`, `noteDetailProvider`. |
| `lib/features/notes/presentation/pages/notes_page.dart` | Daftar catatan (diekstrak dari `home_page.dart`). |
| `lib/features/notes/presentation/pages/note_detail_page.dart` | Pindah dari `lib/pages/`. |
| `lib/features/notes/presentation/widgets/note_tile.dart` | Pindah dari `lib/widgets/` (impor entity domain). |

**Diubah / dihapus**

- `domain/repositories/note_repository.dart` diperluas: `fetchNoteById`,
  `deleteNote`, `countDirty`, `markAllSynced` (semua memakai record + `Failure?`).
- `data/repositories/note_repository_impl.dart` mengimplementasikan seluruh
  kontrak; exception dibungkus `LocalFailure`.
- `lib/pages/home_page.dart` memakai `NotesPage` + provider dari fitur notes.
- `lib/providers/app_providers.dart` hanya menyisakan posts + `forceOffline`.
- `lib/data/sync.dart` hanya menyisakan logika posts.
- Dihapus: `lib/data/local/note.dart`, `lib/data/repositories/note_repository.dart`,
  `lib/pages/note_detail_page.dart`, `lib/widgets/note_tile.dart`.

**Deviasi dari codelab (disengaja & terdokumentasi)**

- `notesProvider` memakai `AsyncNotifier` (bukan `FutureProvider`) karena UI
  butuh mutasi `add`/`delete`/`sync`, bukan sekadar baca.
- `NoteRepositoryImpl(openNotesDb)` memakai parameter posisional (bukan named
  `openDb:`) mengikuti Praktikum 2 agar `prefer_initializing_formals` bersih.
- CRUD satu-baris (add/delete/fetchById) tidak dibuatkan use case — langsung
  repository → notifier (sesuai catatan codelab bahwa itu over-engineering).

### Hasil verifikasi

| Pemeriksaan | Perintah | Hasil |
| :--- | :--- | :--- |
| Presentation steril | `rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/notes/presentation lib/pages` | **0 hasil** ✅ |
| Domain steril | `rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/notes/domain lib/core` | **0 hasil** ✅ |
| Static analysis | `flutter analyze` | **No issues found** ✅ |
| Test | `flutter test` | **7 test lulus** ✅ |

Catatan: grep audit Praktikum 1 (`Repository\(` di `lib/pages`/`lib/providers`)
masih menyisakan `settings_page.dart` (`PrefsRepository()`) dan
`app_providers.dart` (`PostRepository()`) — keduanya fitur **posts/settings**
yang belum direfactor (scope Refactoring Challenge, bukan Praktikum 3 notes).

### Perintah verifikasi (rujukan)

```
# 1. Presentation steril dari data mentah (harus NOL)
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation lib/pages

# 2. Domain steril dari framework & package (harus NOL)
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core

# 3. Static analysis + test
flutter analyze
flutter test
```

## Struktur folder

```
07-week-7-clean-architecture/
├── lib/            # kode aplikasi
├── test/           # unit & widget test
├── docs/           # AI Challenge, usulan vs keputusan final
├── screenshots/    # bukti before/after
└── README.md
```
