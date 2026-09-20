# Laporan Tugas Minggu 4: Networking & REST API

Repository ini berisi implementasi dan hasil verifikasi **Repository Layer** Flutter menggunakan **Dio** dan **Riverpod**, serta dokumentasi pengujian dan verifikasi terhadap kode yang dihasilkan oleh AI Assistant.

---

## 📋 AI Verification Checklist

Berikut adalah hasil verifikasi teknis sebelum kode hasil AI diintegrasikan ke dalam proyek:

### 1. Apakah UI memanggil Dio secara langsung atau lewat repository?
> **Status: ✅ Lewat Repository**  
> UI tidak memiliki ketergantungan langsung ke Dio. Pemanggilan HTTP diisolasi di dalam class [CommentRepository](lib/data/repositories/comment_repository.dart) dan [PostRepository](lib/data/repositories/post_repository.dart). UI hanya mengamati state melalui Riverpod Notifier Provider (`commentListProvider` / `postListProvider` / `pagedPostsProvider`).

---

### 2. Apakah `fromJson` aman null, atau masih memakai cast langsung yang bisa crash?
> **Status: ✅ Aman Null (Null-Safe)**  
> Deserialisasi JSON pada model [Comment](lib/data/models/comment.dart) tidak menggunakan direct casting seperti `json['id'] as int` yang berisiko melempar `TypeError` atau crash jika nilai berupa `null` atau tipe numerik berbeda.
> Digunakan pola safe cast:
> ```dart
> postId: (json['postId'] as num?)?.toInt() ?? 0,
> id: (json['id'] as num?)?.toInt() ?? 0,
> name: json['name'] as String? ?? '',
> email: json['email'] as String? ?? '',
> body: json['body'] as String? ?? '',
> ```

---

### 3. Apakah semua tipe `DioExceptionType` dipetakan ke pesan pengguna?
> **Status: ✅ Terpetakan Lengkap**  
> Fungsi [friendlyErrorMessage](lib/data/providers.dart) memetakan seluruh kategori exception jaringan:
> - **Timeout:** `connectionTimeout`, `sendTimeout`, `receiveTimeout` → *"Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi."*
> - **Koneksi Jaringan:** `connectionError` → *"Tidak dapat terhubung ke server. Periksa internet Anda."*
> - **HTTP 404:** `badResponse` (404) → *"Data tidak ditemukan (404)."*
> - **HTTP 500:** `badResponse` (500) → *"Terjadi kesalahan internal pada server (500). Coba lagi nanti."*
> - **HTTP 401/403:** `badResponse` (401/403) → *"Akses ditolak (code). Periksa kredensial Anda."*
> - **Default / Fallback:** Penanganan error tak terduga lainnya.

---

### 4. Apakah `baseUrl` dan timeout terpusat di satu client?
> **Status: ✅ Terpusat**  
> `baseUrl`, `connectTimeout`, `receiveTimeout`, dan `LogInterceptor` dikonfigurasi secara terpusat di [api_client.dart](lib/data/api_client.dart) dan disediakan melalui `dioProvider` di [providers.dart](lib/data/providers.dart). Repository menerima instance Dio via Dependency Injection.

---

### 5. Apakah test AI benar-benar menguji kasus field hilang, atau hanya happy path?
> **Status: ✅ Menguji Kasus Missing Field & Ditambahkan Edge Cases Mandiri**  
> Pada [test/comment_test.dart](test/comment_test.dart), pengujian mencakup:
> 1. **Happy Path:** Parsing JSON lengkap dengan semua field tersedia.
> 2. **Missing & Null Field:** Menguji field `id` dan `email` yang dihilangkan dari payload serta `name` bernilai `null`.
> 3. **Edge Case Tambahan 1:** Map JSON kosong `{}` tetap aman dan menghasilkan objek `Comment` dengan fallback default.
> 4. **Edge Case Tambahan 2:** Nilai numerik float/double (misal `2.0`, `45.0`) berhasil dikonversi ke integer tanpa error.
> 5. **Unit Test Error Mapping:** Memastikan timeout, connection error, 404, dan 500 menghasilkan pesan ramah pengguna yang sesuai.

---

### 6. Hasil Eksekusi `flutter analyze` dan `flutter test`

#### `flutter analyze`
```bash
$ flutter analyze
Analyzing mobile...
No issues found! (ran in 1.9s)
```
> **Hasil:** 0 error, 0 warning.

#### `flutter test`
```bash
$ flutter test
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
> **Hasil:** Seluruh pengujian (9 test) lolos 100%.

---

## 🛠️ Ringkasan File Implementasi

- [lib/data/models/comment.dart](lib/data/models/comment.dart): Model data `Comment` dengan factory constructor `fromJson` aman null.
- [lib/data/repositories/comment_repository.dart](lib/data/repositories/comment_repository.dart): Repository layer untuk pemanggilan API `/comments?postId={id}`.
- [lib/data/providers.dart](lib/data/providers.dart): Provider Riverpod dan logika penanganan error.
- [test/comment_test.dart](test/comment_test.dart): Unit test model dan error mapping.
