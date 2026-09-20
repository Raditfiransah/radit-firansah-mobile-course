# Laporan AI Prompt Challenge, Verifikasi, dan Hasil Testing
**Mata Kuliah:** Pemrograman Mobile  
**Topik:** Minggu 4 - Networking & REST API (Dio + Riverpod)  
**Mahasiswa:** Radit Firansah  

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

## 2. Output Awal AI

### A. Model Data `Comment` (`lib/data/models/comment.dart`)
```dart
class Comment {
  const Comment({
    required this.postId,
    required this.id,
    required this.name,
    required this.email,
    required this.body,
  });

  final int postId;
  final int id;
  final String name;
  final String email;
  final String body;

  /// Factory constructor untuk deserialisasi JSON secara null-safe dan tahan terhadap missing field.
  factory Comment.fromJson(Map<String, dynamic> json) {
    return Comment(
      postId: (json['postId'] as num?)?.toInt() ?? 0,
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      body: json['body'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'postId': postId,
        'id': id,
        'name': name,
        'email': email,
        'body': body,
      };
}
```

### B. Repository Layer `CommentRepository` (`lib/data/repositories/comment_repository.dart`)
```dart
import 'package:dio/dio.dart';
import '../models/comment.dart';

class CommentRepository {
  CommentRepository(this._dio);

  final Dio _dio;

  Future<List<Comment>> fetchComments(int postId) async {
    final response = await _dio.get<List>(
      '/comments',
      queryParameters: {'postId': postId},
      options: Options(
        sendTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 10),
      ),
    );

    final data = response.data ?? [];
    return data
        .whereType<Map<String, dynamic>>()
        .map(Comment.fromJson)
        .toList();
  }
}
```

### C. State Management & Error Handling (`lib/data/providers.dart`)
```dart
final commentRepositoryProvider = Provider<CommentRepository>(
  (ref) => CommentRepository(ref.watch(dioProvider)),
);

class CommentListNotifier extends AsyncNotifier<List<Comment>> {
  int _currentPostId = 1;

  @override
  Future<List<Comment>> build() async {
    final repository = ref.watch(commentRepositoryProvider);
    return repository.fetchComments(_currentPostId);
  }

  Future<void> loadComments(int postId) async {
    _currentPostId = postId;
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(postId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      final repository = ref.read(commentRepositoryProvider);
      state = AsyncData(await repository.fetchComments(_currentPostId));
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final commentListProvider =
    AsyncNotifierProvider<CommentListNotifier, List<Comment>>(
  CommentListNotifier.new,
  retry: (retryCount, error) => null,
);

String friendlyErrorMessage(Object error) {
  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Koneksi lambat atau timeout. Periksa internet Anda lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke server. Periksa internet Anda.';
      case DioExceptionType.badResponse:
        final code = error.response?.statusCode;
        if (code == 404) return 'Data tidak ditemukan (404).';
        if (code == 500) {
          return 'Terjadi kesalahan internal pada server (500). Coba lagi nanti.';
        }
        if (code == 401 || code == 403) {
          return 'Akses ditolak ($code). Periksa kredensial Anda.';
        }
        return 'Server bermasalah ($code). Coba lagi nanti.';
      default:
        return 'Terjadi kesalahan jaringan. Coba lagi.';
    }
  }
  return 'Terjadi kesalahan tak terduga: $error';
}
```

---

## 3. Perbaikan dan Penyesuaian yang Dilakukan

Setelah kode awal dihasilkan, dilakukan audit dan pengujian mandiri yang menghasilkan beberapa perbaikan:

1. **Perbaikan Struktur Notifier Riverpod:**
   - Menyederhanakan penanganan `AsyncNotifier` agar kompatibel penuh dengan Riverpod tanpa code-generation, serta menambahkan method `loadComments(int postId)` untuk memfasilitasi filter dinamis berdasarkan `postId`.
2. **Penambahan Edge Cases pada Unit Test:**
   - Selain menguji missing fields sesuai prompt, ditambahkan:
     - Edge case pengujian payload Map kosong `{}`.
     - Edge case konversi tipe data numerik backend berupa float/double (misal `2.0`) agar tidak terjadi cast error ke `int`.
     - Unit test pemetaan status code HTTP 404 dan 500 pada `friendlyErrorMessage`.
3. **Pembersihan Lint:**
   - Menghapus unused import pada `main.dart` agar `flutter analyze` bersih (0 warning).
4. **Isolasi Dependency Pengujian Widget:**
   - Memodifikasi `widget_test.dart` menggunakan `FakePostRepository` pada `ProviderScope` overrides untuk mencegah pending timer asinkron Dio saat widget test berjalan.

---

## 4. AI Verification Checklist

| Kriteria Verifikasi | Status | Catatan Analisis |
|---|:---:|---|
| **1. UI memanggil Dio langsung vs Repository** | ✅ Terverifikasi | UI hanya berinteraksi lewat Provider (`commentListProvider`) yang mengonsumsi `CommentRepository`. UI tidak mengakses Dio langsung. |
| **2. `fromJson` aman null** | ✅ Terverifikasi | Menggunakan safe casting `(json['...'] as num?)?.toInt() ?? 0` dan fallback `?? ''`. |
| **3. Pemetaan `DioExceptionType` lengkap** | ✅ Terverifikasi | `friendlyErrorMessage` mencakup timeout, connection error, 404, 500, dan 401/403. |
| **4. Sentralisasi `baseUrl` & Timeout** | ✅ Terverifikasi | Konfigurasi dasar Dio terpusat di `api_client.dart` dan diinjeksi via Riverpod `dioProvider`. |
| **5. Pengujian Missing Field & Edge Case** | ✅ Terverifikasi | Test mencakup missing field, null field, empty map, dan float ID coercion. |
| **6. `flutter analyze` & `flutter test` lolos** | ✅ Terverifikasi | Lolos 100% tanpa error maupun warning. |

---

## 5. Hasil Eksekusi Testing

### A. Hasil `flutter analyze`
```text
$ flutter analyze
Analyzing mobile...
No issues found! (ran in 1.9s)
```

### B. Hasil `flutter test`
```text
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

---

## 6. Panduan Penjelasan Kode untuk Demo

Saat sesi demo, berikut adalah poin-poin penjelasan penting untuk setiap file:

1. **`lib/data/models/comment.dart`:**
   - **Tujuan:** Representasi immutable data transfer object (DTO) untuk entitas Comment.
   - **Kunci Penjelasan:** Di dalam `Comment.fromJson()`, tipe integer di-cast menggunakan `(json['postId'] as num?)?.toInt() ?? 0`. Mengapa `num?`? Karena di JSON numerik dapat diparsing sebagai `int` atau `double`. Dengan `num?`, casting tidak akan crash jika server mengirimkan format float, dan operator `?? 0` memberikan nilai default saat key bernilai `null` atau tidak ada.

2. **`lib/data/repositories/comment_repository.dart`:**
   - **Tujuan:** Mengabstraksi komunikasi HTTP via Dio agar UI dan Notifier tidak terikat dengan detail protokol HTTP.
   - **Kunci Penjelasan:** `fetchComments(int postId)` menerima parameter `postId`, menyertakan query parameters `{'postId': postId}`, serta menyematkan `Options` timeout 10 detik. Menggunakan `whereType<Map<String, dynamic>>()` sebelum mapping untuk memvalidasi elemen respons JSON.

3. **`lib/data/providers.dart`:**
   - **Tujuan:** Menyediakan instance repository (`commentRepositoryProvider`) dan mengelola state asinkron (`CommentListNotifier` / `commentListProvider`).
   - **Kunci Penjelasan:** `AsyncNotifier` menangani siklus asinkron (Loading, Data, Error) secara deklaratif. Di dalam `friendlyErrorMessage`, `DioException.type` dan `statusCode` diterjemahkan ke pesan yang ramah pengguna.

4. **`test/comment_test.dart`:**
   - **Tujuan:** Memverifikasi keandalan deserialisasi JSON terhadap berbagai format payload ekstrem (missing key, null, empty map, numeric float) dan memastikan fungsi error mapping bekerja akurat.
