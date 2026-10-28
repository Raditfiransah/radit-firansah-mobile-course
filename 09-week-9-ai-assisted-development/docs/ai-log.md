# AI Log — Fitur Pencarian Judul Catatan (Minggu 9)

Dokumen ini memenuhi bagian **AI Prompt Challenge + AI Verification Checklist**
Minggu 9: prompt, output awal AI, langkah verifikasi, bukti halusinasi/test
merah, refactor, dan tabel keputusan terima/tolak.

> **Catatan kejujuran:** "AI" di sini adalah asisten yang sama dengan penulis
> kode. Draft awal sengaja dihasilkan apa adanya (termasuk kelemahannya), lalu
> dibuktikan salah lewat test — bukan AI independen dan bukan hasil yang
> ditempel mentah. Review di PR juga disimulasikan (repo solo).

---

## 1. Prompt (5 slot)

```text
Peran: senior Flutter dev.

Konteks:
- Project: week5_offline_notes (lanjutan Minggu 5–8), feature-first
  Clean Architecture: presentation -> domain <- data.
  Domain tidak boleh impor Flutter/Dio/SQLite.
- State & DI: flutter_riverpod 2.6, GoRouter 18, sqflite, dio.
- File relevan:
  lib/features/notes/domain/entities/note.dart
    class Note { final int? id; final String title; final String body;
                 final DateTime updatedAt; final bool dirty; }
  lib/features/notes/domain/repositories/note_repository.dart
    abstract class NoteRepository { Future<({List<Note> notes, Failure? failure})> fetchNotes(); ... }
  lib/features/notes/presentation/providers/notes_providers.dart
    final notesProvider = AsyncNotifierProvider<NotesNotifier, List<Note>>(...);
  lib/features/notes/presentation/pages/notes_page.dart  (ListView + onTap ke /note/:id)

Tugas: tambah pencarian judul notes + empty state.

Batas:
- Jangan ubah arsitektur (presentation->domain<-data).
- Jangan panggil SQLite dari widget.
- Maksimal 80 baris kode baru, tanpa dependency baru.
- Jangan sertakan token/secret apa pun.

Output: kode + 3 test case + cara uji.
```

Konteks yang **tidak** disertakan: seluruh repo, token, JWT, API key.

---

## 2. Output awal AI (draft pertama)

```dart
import '../entities/note.dart';

class SearchNotes {
  const SearchNotes();

  List<Note> call(List<Note> notes, String query) {
    if (query.isEmpty) return notes;
    return notes.where((note) => note.title.contains(query)).toList();
  }
}
```

Draft ini terlihat benar dan lolos `flutter analyze`, tetapi punya dua cacat
logika:

1. `String.contains` **case-sensitive** — `"BELANJA"` tidak menemukan
   `"Belanja mingguan"`.
2. `query.isEmpty` tidak menangani spasi — query `"   "` dianggap pencarian dan
   mengembalikan **kosong**, padahal seharusnya semua catatan.

Ini pola halusinasi "logika yakin tapi salah": kode valid secara sintaks, tetapi
aturan bisnisnya keliru.

---

## 3. Verifikasi 6 langkah + bukti test merah

### Langkah 1 — baca tiap baris

`contains` tanpa normalisasi casing dan `query.isEmpty` tanpa `trim()` ditandai
sebagai kandidat bug.

### Langkah 2 — cek import

```bash
$ rg "import 'package:flutter|import 'package:dio|import 'package:sqflite" lib/features/notes/domain
# → 0 matches
```

`SearchNotes` hanya mengimpor entity domain. Dependency rule aman.

### Langkah 3 — cek API

`trim()`, `toLowerCase()`, `String.contains()` adalah API inti `dart:core`
(bukan method fiktif / package kadaluarsa). Tidak ada dependency baru.

### Langkah 4 — test merah pembukti bug

Test ditulis lebih dulu (`test/search_notes_test.dart`) mencakup kasus sukses,
tidak cocok, dan query kosong/spasi. Hasil pada draft AI:

```text
$ flutter test test/search_notes_test.dart
00:00 +0 -1: filter judul mengabaikan huruf besar/kecil [E]
  Expected: an object with length of <2>
    Actual: [Instance of 'Note']
     Which: has length of <1>

00:00 +1 -2: query kosong atau spasi mengembalikan semua catatan [E]
  Expected: an object with length of <3>
    Actual: []
     Which: has length of <0>

00:00 +1 -2: Some tests failed.
```

Bukti visual: [`screenshots/01-red-test-case-sensitive.png`](../screenshots/01-red-test-case-sensitive.png).

### Langkah 5 — perbaiki kecil

```dart
List<Note> call(List<Note> notes, String query) {
  final normalized = query.trim().toLowerCase();
  if (normalized.isEmpty) return notes;
  return notes
      .where((note) => note.title.toLowerCase().contains(normalized))
      .toList();
}
```

Akar masalah: normalisasi input dan judul tidak dilakukan sebelum perbandingan.

### Langkah 6 — analyze + test + uji manual

```bash
$ flutter test test/search_notes_test.dart
00:00 +3: All tests passed!
```

Uji manual 3 query di tab **Catatan** (ditutup widget test karena environment
tanpa emulator):

| Query | Harapan | Bukti |
| :--- | :--- | :--- |
| kosong | semua catatan | `test/search_notes_test.dart` — query kosong/spasi → 3 item |
| `BELANJA` | cocok case-insensitive | `notes_search_widget_test.dart` — hanya `Belanja mingguan` tampil |
| `zzz-tidak-ada` | empty state | `notes_search_widget_test.dart` — teks *Tidak ada catatan yang cocok dengan "zzz-tidak-ada".* |

---

## 4. Refactor ke layer yang benar

- **Widget** (`notes_page.dart`): hanya `TextField`, state query, dan render
  daftar/empty state.
- **Notifier/provider** (`notes_providers.dart`): `searchQueryProvider` (state
  UI) + `searchNotesProvider` (DI use case).
- **Use case** (`domain/usecases/search_notes.dart`): aturan filter murni,
  tanpa I/O.
- **Repository**: tidak berubah — pencarian dilakukan di memori atas daftar yang
  sudah dimuat, bukan query SQL dari widget.

Tidak ada panggilan database dari widget; tidak ada import lintas layer.

---

## 5. AI review kode search (3 temuan)

Prompt review:

```text
Review kode search Flutter ini sebagai senior dev.
Konteks: feature-first (presentation->domain<-data), Riverpod, SQLite + Dio.
Fokus: kebenaran, arsitektur, test. Abaikan style.
Beri 3 temuan + level blocker/saran + alasan.
```

| # | Level | Temuan | Benar? | Bukti | Keputusan |
| :-- | :--- | :--- | :--- | :--- | :--- |
| 1 | saran | `TextField` berada di dalam `notesAsync.when(data:)` sehingga hilang saat `loading`/`error` dan saat daftar kosong | **Ya** | Commit `5d9ac75`: `notesAsync.when` baris 15, `notes.isEmpty` return baris 20, `TextField` baris 30 | **Diterima** — field di-hoist ke atas `.when` (commit `f7fdb9f`: field baris 20, `.when` baris 32) |
| 2 | test | Belum ada widget test untuk state *belum ada catatan* + kolom cari tetap tampil | **Ya** | `notes_search_widget_test.dart` di `5d9ac75` hanya 2 test | **Diterima** — test ketiga ditambahkan (`kolom pencarian tetap ada saat daftar masih kosong`) |
| 3 | saran | Tambahkan debounce `Timer` pada query | Ya sebagai pola umum, **tidak** sebagai kebutuhan di sini | Filter berjalan in-memory pada `List<Note>` lokal, tanpa I/O | **Ditolak** — menambah state + dispose + test tanpa manfaat terukur untuk daftar < 100 item |

Ringkasan: **2 diterima**, **1 ditolak** — memenuhi syarat minimal 1 temuan
benar berbukti dan 1 ditolak dengan alasan.

### Keputusan per file

| File | Keputusan |
| :--- | :--- |
| `domain/usecases/search_notes.dart` | **Terima + refactor** (normalisasi casing/trim, murni domain) |
| `presentation/providers/notes_providers.dart` | **Terima** (provider use case + state query) |
| `presentation/pages/notes_page.dart` | **Terima + refactor** (field di-hoist, dua empty state) |
| `test/search_notes_test.dart` | **Terima** (3 kasus, termasuk pembukti bug) |
| `test/notes_search_widget_test.dart` | **Terima + tambah** (empty state + case-insensitive + daftar kosong) |

---

## 6. Bukti akhir

```bash
$ flutter analyze
No issues found! (ran in 2.4s)

$ dart format --set-exit-if-changed .
Formatted 38 files (0 changed) in 0.08 seconds.

$ flutter test
00:01 +21: All tests passed!
```

CI `verify` (analyze + format + test) hijau pada commit `f7fdb9f`
([run 40615000490](https://github.com/Raditfiransah/radit-firansah-mobile-course/actions/runs/40615000490)).
PR #8 di-squash menjadi `1f8c7c9` dan issue #7 tertutup otomatis.