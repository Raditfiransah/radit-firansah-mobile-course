# Dokumentasi Tugas Minggu 4: AI Prompt Challenge & Verification Report

Dokumen ini mencatat seluruh proses implementasi repository layer dengan bantuan AI assistant, mencakup prompt yang digunakan, output awal, perbaikan/penyesuaian yang dilakukan, hasil checklist verifikasi, serta hasil pengujian otomatis.

---

## 1. Prompt yang Digunakan

```text
Buatkan repository layer Flutter untuk endpoint GET /comments?postId={id}
dari JSONPlaceholder menggunakan Dio + flutter_riverpod.
Requirements:
- Model Comment dengan fromJson aman null (postId, id, name, email, body).
- CommentRepository dengan method fetchComments(postId) + timeout 10 detik.
- AsyncNotifierProvider dengan penanganan error otomatis (AsyncError)
  dan fungsi pesan error ramah pengguna untuk timeout, connection error, 404, dan 500.
- Satu unit test untuk fromJson dengan field yang hilang.
Jelaskan setiap bagian kode dalam komentar.
```

---

## 2. Output Awal AI & Analisis Kode

### Model `Comment`
- **File:** `mobile/lib/data/models/comment.dart`
- **Analisis:** Menggunakan casting safe `(json['...'] as num?)?.toInt() ?? 0` dan `json['...'] as String? ?? ''`. Menghindari crash akibat `TypeError` atau `Null check operator used on a null value`.

### Repository `CommentRepository`
- **File:** `mobile/lib/data/repositories/comment_repository.dart`
- **Analisis:** Mengimplementasikan method `fetchComments(int postId)` dengan parameter query `{'postId': postId}` dan `Options` timeout 10 detik. Menggunakan dependency injection instance `Dio`.

### State Management & Error Handling
- **File:** `mobile/lib/data/providers.dart`
- **Analisis:** Menggunakan `AsyncNotifier<List<Comment>>` dan `commentListProvider`. Exception dari pemanggilan API otomatis bertransformasi menjadi state `AsyncError`. Fungsi `friendlyErrorMessage` mengonversi exception teknis Dio menjadi pesan ramah pengguna.

### Unit Testing
- **File:** `mobile/test/comment_test.dart`
- **Analisis:** Menguji deserialisasi JSON missing field, empty JSON, tipe data floating-point ke integer, dan pemetaan seluruh pesan error ramah pengguna.

---

## 3. Perbaikan & Penyesuaian yang Dilakukan (Refinement)

1. **Perbaikan Notifier pada Riverpod:**
   - Menyesuaikan `CommentListNotifier` agar menggunakan `AsyncNotifier<List<Comment>>` dengan method `loadComments(int postId)` dan `refresh()` yang terintegrasi secara modular dengan `commentRepositoryProvider`.
2. **Penambahan Edge Cases pada Unit Test:**
   - Menambahkan test case parsing Map kosong `{}`.
   - Menambahkan test case konversi tipe data numerik dari `double` ke `int`.
3. **Pembersihan Lint & Warning:**
   - Menghapus unused import pada `main.dart`.
   - Menyesuaikan `widget_test.dart` agar meng-override repository dengan implementasi mock/fake untuk mencegah pending timer saat pengujian widget.

---

## 4. AI Verification Checklist

| No | Kriteria Verifikasi | Evaluasi | Catatan |
|---|---|:---:|---|
| 1 | Apakah UI memanggil Dio secara langsung atau lewat repository? | ✅ | UI hanya berinteraksi lewat Provider (`commentListProvider`) yang mengonsumsi `CommentRepository`. |
| 2 | Apakah `fromJson` aman null, atau masih memakai cast langsung yang bisa crash? | ✅ | Semua parsing field memakai safe cast (`as num?`, `as String?`) dengan nilai default fallback. |
| 3 | Apakah semua tipe `DioExceptionType` dipetakan ke pesan pengguna? | ✅ | `friendlyErrorMessage` memetakan timeout, connection error, 404, dan 500 secara spesifik. |
| 4 | Apakah `baseUrl`/timeout terpusat di satu client? | ✅ | Dio client dikonfigurasi terpusat di `api_client.dart` dan diinjeksikan via `dioProvider`. |
| 5 | Apakah test AI benar-benar menguji kasus field hilang, atau hanya happy path? | ✅ | Menguji missing field, null field, serta 2 edge case tambahan (empty map & float conversion). |
| 6 | Jalankan `flutter analyze` dan `flutter test`, apakah lolos tanpa warning? | ✅ | `flutter analyze` = 0 issues, `flutter test` = 9/9 tests passed. |

---

## 5. Hasil Eksekusi Testing

### A. `flutter analyze`
```text
Analyzing mobile...
No issues found! (ran in 1.9s)
```

### B. `flutter test`
```text
00:00 +0: loading /home/radit/Polinema/radit-firansah-mobile-course/04-week-4-networking-rest-api/mobile/test/widget_test.dart
00:00 +0: /home/radit/Polinema/radit-firansah-mobile-course/04-week-4-networking-rest-api/mobile/test/widget_test.dart: App smoke test loads MaterialApp
00:01 +1: /home/radit/Polinema/radit-firansah-mobile-course/04-week-4-networking-rest-api/mobile/test/comment_test.dart: Comment.fromJson berhasil parsing JSON lengkap (Happy Path)
00:01 +2: /home/radit/Polinema/radit-firansah-mobile-course/04-week-4-networking-rest-api/mobile/test/comment_test.dart: Comment.fromJson aman null saat beberapa field hilang atau null (Missing & Null Fields)
00:01 +3: /home/radit/Polinema/radit-firansah-mobile-course/04-week-4-networking-rest-api/mobile/test/comment_test.dart: Comment.fromJson Edge Case: aman null saat JSON berupa map kosong {}
00:01 +4: /home/radit/Polinema/radit-firansah-mobile-course/04-week-4-networking-rest-api/mobile/test/comment_test.dart: Comment.fromJson Edge Case: tipe data numerik berupa double / float berhasil dikonversi ke int
00:01 +5: /home/radit/Polinema/radit-firansah-mobile-course/04-week-4-networking-rest-api/mobile/test/comment_test.dart: friendlyErrorMessage memetakan DioExceptionType.connectionTimeout ke pesan ramah timeout
00:01 +6: /home/radit/Polinema/radit-firansah-mobile-course/04-week-4-networking-rest-api/mobile/test/comment_test.dart: friendlyErrorMessage memetakan DioExceptionType.connectionError ke pesan ramah koneksi
00:01 +7: /home/radit/Polinema/radit-firansah-mobile-course/04-week-4-networking-rest-api/mobile/test/comment_test.dart: friendlyErrorMessage memetakan status code 404 ke pesan data tidak ditemukan
00:01 +8: /home/radit/Polinema/radit-firansah-mobile-course/04-week-4-networking-rest-api/mobile/test/comment_test.dart: friendlyErrorMessage memetakan status code 500 ke pesan server bermasalah
00:01 +9: All tests passed!
```
