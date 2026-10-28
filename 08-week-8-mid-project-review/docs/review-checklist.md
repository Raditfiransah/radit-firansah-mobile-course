# Review Checklist — Mid Project (Minggu 8)

Dokumen ini memenuhi Praktikum Minggu 8: audit riwayat Git, perbaikan pesan
commit, dan penilaian kesiapan project tengah semester untuk
`07-week-7-clean-architecture`.

---

## 1. Audit riwayat Git

Perintah yang dijalankan di root repository:

```bash
git log --oneline -15
git branch -a
git status
```

### Temuan audit

| Temuan | Bukti | Dampak | Tindakan |
| :--- | :--- | :--- | :--- |
| Commit lama langsung ke `main` | `git log` — semua commit Minggu 1–7 ada di `main`, tanpa PR/issue | Tidak ada jejak review; riwayat tidak bisa direview per fitur | Tidak bisa diperbaiki retroaktif. Sejak Minggu 8 semua perubahan lewat `develop` + PR |
| Pesan commit tidak konvensional | `e725b52 week 6`, `3f4b21e week 6`, `8286988 week-5` | Sulit dicari/di-revert | Ditulis ulang sebagai rekomendasi di §2 |
| Konfigurasi IDE ikut ter-commit | `e725b52` & `8286988` memuat `.idea/caches/deviceStreaming.xml` (2.385 baris) | Noise besar di diff, konflik antar mesin | Dicatat; kandidat `git rm -r --cached .idea` di pekerjaan terpisah |
| Screenshot dicampur dengan kode | `8286988` memuat project + 4 screenshot sekaligus | Commit tidak satu tujuan | Rekomendasi dipecah (lihat §2) |
| Belum ada branch `feature/*`/`fix/*` sebelum Minggu 8 | `git branch -a` hanya `main` | Kerja harian tidak terisolasi | Dibuat `develop` + `feature/*`/`chore/*` pada Minggu 8 |
| File tak terlacak | `git status` bersih; `build/`, `.dart_tool/` sudah di-`.gitignore` | — | OK |

### Kondisi setelah Minggu 8

```bash
$ git log --oneline -5
3c1733b feat(notes): validasi judul kosong + test (#4)
4a4b428 chore(format): apply dart format to week 7 project (#2)
3183deb feat(web): add screenshot
45e65ae refactor: apply clean architecture to posts and settings
02fa62e docs: add week 7 AI challenge analysis

$ git branch -a
* develop
  main
```

`main` tidak disentuh; `develop` menjadi default branch; branch fitur dihapus
setelah merge.

---

## 2. Tiga commit lama → format konvensional

Format: `tipe(scope): deskripsi singkat`.

| Sebelum | Sesudah (rekomendasi) | Alasan |
| :--- | :--- | :--- |
| `e725b52 week 6` | `feat(week6): add campus_notify auth + FCM project`<br>*(idealnya dipecah lagi: `chore(ide): add Android Studio config`)* | Menyebut tipe + scope + isi. Commit ini mencampur project dan `.idea/`, jadi pemisahan membuat diff bisa direview dan di-revert terpisah. |
| `3f4b21e week 6` | `docs(week6): add FCM and UI screenshots` | Isinya hanya 4 file PNG; tipe `docs` lebih tepat daripada pesan generik "week 6". |
| `8286988 week-5` | `feat(week5): add offline-first notes project`<br>*(+ `docs(week5): add screenshots`)* | Judul langsung menyatakan fitur; screenshot dipisah agar commit kode tetap satu tujuan. |

Prinsip yang dipakai: satu commit = satu perubahan logis yang bisa direview dan
di-revert; pesan menjelaskan **apa** dan **di mana** (`scope`), bukan "update"
atau "fix bug".

---

## 3. Standar branch, commit, dan PR yang diterapkan

| Aturan | Penerapan Minggu 8 |
| :--- | :--- |
| `main` selalu rilis, tanpa commit langsung | `main` tidak disentuh |
| `develop` = integrasi, target default PR | Dibuat dari `main`, dijadikan default branch |
| `feature/*` / `chore/*` pendek (< 3 hari) | `chore/format-baseline`, `feat/notes-validation`, `docs/08-mid-review` |
| Satu PR = satu tujuan, < 300 baris | PR #4: 6 file, +201/−42 (243 baris) |
| PR memuat masalah → solusi → cara uji → screenshot | Template dipakai di PR #2, #4, #6 |
| Issue ditutup otomatis oleh PR | `Closes #1`, `Closes #3`, `Closes #5` → ketiganya `CLOSED` |
| `analyze` + `test` hijau sebelum review | Dijalankan lokal dan di CI |

---

## 4. Peer review yang dilakukan

Review diposting di PR #4
([komentar review](https://github.com/Raditfiransah/radit-firansah-mobile-course/pull/4)).
Karena repo solo, reviewer adalah AI + verifikasi manual penulis (limitasi
dicatat di README).

| Kategori | Temuan | Keputusan |
| :--- | :--- | :--- |
| Kebenaran | Tombol **Simpan** tetap aktif saat `await` → double-submit membuat catatan kembar | **Diterima**, diperbaiki (`saving` guard) |
| Kebenaran | `errorText` tidak hilang saat judul diperbaiki | **Diterima**, diperbaiki (`onChanged`) |
| Arsitektur | Kontrak error notifier tidak konsisten (`addNote` → `Failure?`, `deleteNote`/`sync` → `throw`) | **Ditunda** — menyentuh 3 method + call site, di luar scope PR kecil; dicatat backlog |
| Test | Belum ada test yang membuktikan `LocalFailure` dari repository diteruskan use case | **Diterima**, test ditambahkan |
| Keterbacaan | Dialog 60+ baris di `HomePage` sebaiknya diekstrak jadi widget fitur | **Ditunda** — refactor terpisah, bukan blocker |

Verdict akhir: **Approve** setelah 3 temuan diterima diperbaiki dan CI hijau.

---

## 5. Penilaian kesiapan tengah semester

| Item | Bukti | Status |
| :--- | :--- | :--- |
| Struktur feature-first | 3 grep sterilitas, semuanya **0 hasil** (§6) | ✅ |
| `flutter analyze` bersih | `No issues found!` | ✅ |
| Format rapi | `dart format --set-exit-if-changed .` → 35 file, 0 berubah | ✅ |
| Test hijau | `flutter test` → 15 test lulus | ✅ |
| PR kecil + commit jelas | PR #4: 243 baris, 3 commit konvensional | ✅ |
| README + screenshot + cara menjalankan | `08-week-8-mid-project-review/README.md` + `screenshots/` | ✅ |
| Komentar review ditindaklanjuti | 3 diterima & diperbaiki, 2 ditolak/ditunda dengan alasan | ✅ |
| Issue tertutup via PR | Issue #1, #3, #5 berstatus `CLOSED` | ✅ |
| CI menolak PR kotor | `.github/workflows/ci.yml` → run `success` | ✅ |
| AI review terdokumentasi | `docs/ai-review-vs-keputusan.md` | ✅ |

**Definisi selesai (codelab):** aplikasi berjalan identik dengan akhir Minggu 7
(+ perbaikan validasi yang disengaja), tiga pemeriksaan mesin hijau, minimal satu
PR kecil ter-merge via review, dan README memuat status paruh semester + peta
issue/PR. **Semua terpenuhi.**

---

## 6. Bukti verifikasi mesin

### Tiga grep sterilitas (dijalankan di `07-week-7-clean-architecture`)

```bash
# 1. Presentation steril dari akses data mentah
rg "Dio\(|openDatabase|getDatabasesPath|FlutterSecureStorage|SharedPreferences\.getInstance|jsonDecode" lib/features/*/presentation lib/pages
# → 0 matches

# 2. Domain + core steril dari framework/package
rg "import 'package:flutter|import 'package:dio|import 'package:sqflite|import 'package:firebase" lib/features/*/domain lib/core
# → 0 matches

# 3. DI bocor di presentation
rg "Repository\(|Dio\(BaseOptions" lib/pages
# → 0 matches  (folder lib/providers sudah dihapus pada Minggu 7)
```

### Perintah mesin

```bash
$ flutter analyze
No issues found! (ran in 2.2s)

$ dart format --set-exit-if-changed .
Formatted 35 files (0 changed) in 0.08 seconds.

$ flutter test
00:01 +15: All tests passed!
```

Bukti visual: [`../screenshots/01-verify-analyze-format-test.png`](../screenshots/01-verify-analyze-format-test.png)
dan [`../screenshots/02-git-flow-ci-merge.png`](../screenshots/02-git-flow-ci-merge.png).