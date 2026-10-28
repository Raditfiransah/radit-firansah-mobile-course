# AI Review vs Keputusan Final — PR #4

Dokumen ini memenuhi bagian **AI Prompt Challenge + AI Verification Checklist**
Minggu 8. Isinya: prompt yang dipakai, output awal AI, tabel verifikasi tiap
temuan dengan bukti, dan keputusan final beserta alasannya.

> **Catatan kejujuran:** AI reviewer pada praktikum ini adalah asisten yang sama
> dengan penulis kode, jadi output AI **tidak** diterima mentah. Setiap temuan
> diverifikasi dengan `grep`, test, atau membaca ulang diff sebelum diputuskan.
> Review di PR juga disimulasikan (repo solo) — lihat `README.md` §Limitasi.

---

## 1. Prompt yang dipakai

Prompt asli codelab (disalin apa adanya):

```text
Review PR Flutter ini sebagai senior Flutter dev.
Konteks: feature-first Clean Architecture (presentation -> domain <- data),
Riverpod, GoRouter, SQLite + Dio.
Fokus: kebenaran, arsitektur, dan test. Abaikan style.
Berikan 5 temuan teratas + level (blocker/saran)
+ alasan + usulan potongan kode perbaikan.
```

Konteks yang disertakan: PR #4 (`feat/notes-validation` → `develop`), diff
`lib/core/failures.dart`, `lib/features/notes/domain/usecases/add_note.dart`,
`lib/features/notes/presentation/providers/notes_providers.dart`,
`lib/pages/home_page.dart`, `test/add_note_test.dart`.

---

## 2. Output awal AI (5 temuan)

Singkat, sebelum diverifikasi:

1. **[blocker] Double-submit.** `FilledButton` tetap aktif selama `await
   addNote`; tap dua kali cepat membuat dua catatan kembar.
2. **[saran] `errorText` basi.** Pesan error tidak hilang saat pengguna
   memperbaiki judul; baru hilang pada submit berikutnya.
3. **[saran] Pindahkan validasi ke `TextFormField.validator` di presentation.**
4. **[test] Gap:** belum ada test yang membuktikan `LocalFailure` dari
   repository diteruskan oleh `AddNote`.
5. **[arsitektur] Kontrak error tidak konsisten.** `addNote` mengembalikan
   `Failure?`, sedangkan `deleteNote` dan `sync` melempar `Exception`.

---

## 3. Tabel verifikasi (AI Verification Checklist)

| # | Temuan | Benar-benar ada? | Bukti | Melanggar dependency rule? | Sekadar nitpick style? | Keputusan |
| :-- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | Double-submit | **Ya** | `git show 784adac:.../home_page.dart` → hanya `onPressed: () async`, tidak ada guard `saving`/disable | Tidak | Tidak — ini bug perilaku | **Diterima**, diperbaiki |
| 2 | `errorText` basi | **Ya** | Commit yang sama: field judul tidak punya `onChanged`; `error` hanya di-set saat submit | Tidak | Tidak — UX error state | **Diterima**, diperbaiki |
| 3 | Validasi di `TextFormField.validator` | Ya sebagai pola, **tidak** sebagai perbaikan | Validasi domain sudah ada di `AddNote` dan diuji tanpa widget | Tidak, tapi menggandakan aturan | Tidak | **Ditolak** — duplikasi single source of truth, aturan jadi tidak bisa diuji murni |
| 4 | Test gap failure forwarding | **Ya** | `git show 784adac:.../add_note_test.dart` → 2 `test(`; tidak ada kasus repository gagal | Tidak | Tidak | **Diterima**, test ditambahkan (total 3) |
| 5 | Kontrak error inkonsisten | **Ya** | `rg -n "throw Exception|Future<Failure\\?>" notes_providers.dart` → `throw` di baris 40, 59, 67 vs `Future<Failure?>` di baris 45 | Tidak | Tidak | **Ditunda** — menyentuh 3 method + call site; di luar scope PR 243 baris. Dicatat backlog |

Ringkasan: **3 diterima** (1, 2, 4), **2 ditolak/ditunda** (3, 5) — memenuhi
syarat minimal 2 temuan benar berbukti dan minimal 1 ditolak dengan alasan.

---

## 4. Perbaikan yang diterapkan

### Temuan 1 — guard double-submit

```dart
var saving = false;

FilledButton(
  onPressed: saving
      ? null
      : () async {
          setDialogState(() {
            error = null;
            saving = true;
          });
          final failure = await ref
              .read(notesProvider.notifier)
              .addNote(title: titleCtrl.text, body: bodyCtrl.text.trim());
          if (!ctx.mounted) return;
          if (failure != null) {
            setDialogState(() {
              error = failure.message;
              saving = false;
            });
            return;
          }
          Navigator.pop(ctx);
        },
  child: const Text('Simpan'),
)
```

### Temuan 2 — reset error saat mengetik

```dart
TextField(
  controller: titleCtrl,
  decoration: InputDecoration(
    labelText: 'Judul',
    border: const OutlineInputBorder(),
    errorText: error,
  ),
  onChanged: (_) {
    if (error != null) setDialogState(() => error = null);
  },
  autofocus: true,
)
```

### Temuan 4 — test failure forwarding

```dart
test('AddNote meneruskan failure dari repository', () async {
  final repo = _FakeNoteRepository(fail: true);
  final result = await AddNote(repo).call(title: 'Judul valid');

  expect(result.failure, isA<LocalFailure>());
  expect(result.note, isNull);
});
```

Bukti sesudah perbaikan (commit squash `3c1733b`):

```bash
$ git show 3c1733b:.../home_page.dart | grep -n "saving\|onChanged"
131:    var saving = false;
148:                onChanged: (_) {
170:              onPressed: saving
175:                        saving = true;
187:                          saving = false;

$ git show 3c1733b:.../add_note_test.dart | grep -c "test("
3
```

---

## 5. Temuan yang ditolak — alasan tertulis

### Temuan 3 — validasi pindah ke presentation

Ditolak karena:

1. **Single source of truth.** Aturan "judul tidak boleh kosong" sudah ada di
   `AddNote`. Menambah `TextFormField.validator` berarti dua tempat yang bisa
   berbeda hasilnya (mis. trim vs tidak trim).
2. **Testability.** Aturan domain sekarang diuji murni (`test/add_note_test.dart`)
   tanpa `WidgetTester`; validator presentasi memaksa test widget untuk aturan
   bisnis.
3. **Dependency rule tetap aman,** tetapi codelab Minggu 8 meminta validasi di
   use case + pesan error di UI — bukan dua validasi.

### Temuan 5 — kontrak error notifier

Benar, tetapi **ditunda**, bukan dibantah. Mengubah `deleteNote` dan `sync`
untuk mengembalikan `Failure?` menyentuh 2 method notifier, 2 call site
(`notes_page.dart`, `note_detail_page.dart`, `home_page.dart`), dan test —
melebihi tujuan PR kecil ini (< 300 baris, satu fitur). Dicatat sebagai backlog
refactor terpisah; tidak ada bug yang lolos karena jalur `throw` sudah ada
sejak Minggu 7 dan test widget/error path tetap lulus.

---

## 6. Keputusan final

- **Merge PR #4** setelah temuan 1, 2, 4 diperbaiki dan CI `verify` hijau
  ([run 40612331338](https://github.com/Raditfiransah/radit-firansah-mobile-course/actions/runs/40612331338)).
- Temuan 3 ditolak (alasan teknis di §5), temuan 5 ditunda (backlog).
- Keputusan boleh berbeda dari AI selama berargumen dan berbukti — itulah yang
  dicatat di tabel §3, bukan sekadar menempel komentar AI.

### Bukti akhir

```bash
$ flutter analyze
No issues found!

$ dart format --set-exit-if-changed .
Formatted 35 files (0 changed)

$ flutter test
+15: All tests passed!
```