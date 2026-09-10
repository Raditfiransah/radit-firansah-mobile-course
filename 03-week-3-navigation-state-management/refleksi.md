# Refleksi Praktikum 3 — Uji Tiga State (AsyncNotifier & AsyncValue)

## 1. Hasil Pengujian State

### A. Loading State (2 Detik Pertama)
Saat `ProductPage` dibuka pertama kali, `productsProvider` mengeksekusi method `build()` yang menunda pengembalian data selama 2 detik (`await Future.delayed(...)`).
- **UI State:** Tampilan menampilkan `CircularProgressIndicator()` di tengah layar.
- **Penjelasan:** Widget `productsAsync.when(...)` menangkap status `AsyncLoading` dan me-render komponen loading secara responsif.

### B. Error State & Tombol "Coba lagi"
Ketika `build()` dimodifikasi sementara untuk melempar exception (`throw Exception('Gagal terhubung ke server');`):
- **UI State:** Tampilan secara otomatis berganti menampilkan teks error `Gagal memuat: Exception: Gagal terhubung ke server` beserta tombol `FilledButton` bertuliskan **Coba lagi**.
- **Penjelasan:** Exception ditangkap oleh Riverpod dan diubah menjadi `AsyncError`. Memanggil `ref.invalidate(productsProvider)` pada tombol **Coba lagi** memaksa provider untuk me-reset state dan mengeksekusi `build()` kembali dari awal.

### C. Success State (Dipulihkan)
Setelah exception dihapus dan `build()` dikembalikan untuk mengembalikan data list produk `['Keyboard', 'Mouse', 'Monitor']`:
- **UI State:** Setelah loading 2 detik selesai, layar menampilkan daftar produk menggunakan `ListView.builder`.
- **Penjelasan:** State berubah menjadi `AsyncData` dan me-render UI daftar produk secara sukses.

---

## 2. Refleksi: Stale-While-Revalidate vs Mengosongkan Layar

> **Pertanyaan:** Mengapa menampilkan ulang data lama (*stale data*) dengan indikator refresh kadang lebih baik daripada mengosongkan layar? Kapan pola itu penting?

### Mengapa Menampilkan Data Lama (*Stale Data*) Lebih Baik?
1. **Meningkatkan *Perceived Performance* (Persepsi Kinerja):**
   Aplikasi terasa jauh lebih cepat dan responsif karena pengguna langsung melihat konten tanpa dihadapkan pada layar kosong (*blank screen*) atau spinner pemuatan utama.
2. **Menjaga Kontinuitas Konteks Visual (UX Continuity):**
   Mengosongkan layar setiap kali terjadi pembaruan data (*refresh*) menyebabkan *layout flashing* atau pergeseran antarmuka yang mengganggu. Dengan mempertahankan data lama, posisi scroll dan fokus pengguna tidak hilang.
3. **Ketersediaan Informasi Saat Koneksi Buruk / Terputus:**
   Jika pembaruan latar belakang (*background refresh*) gagal akibat koneksi internet yang labil, pengguna tetap dapat mengakses informasi terakhir yang tersimpan (*cached/stale data*) daripada disajikan halaman kosong atau pesan error yang memblokir layar.

### Kapan Pola Ini Sangat Penting?
- **Aplikasi Social Media & News Feeds:** (contoh: Twitter, Instagram) Pengguna dapat terus membaca postingan yang sudah dimuat sebelumnya selagi data baru ditarik melalui *pull-to-refresh*.
- **Dashboard Finansial & Analitik:** Informasi ringkasan akun atau grafik tetap dapat dibaca oleh pengguna saat aplikasi menyelaraskan angka terbaru di latar belakang.
- **Katalog E-Commerce & Daftar Produk:** Pengguna tidak kehilangan konteks item yang sedang mereka amati saat memicu pembaruan filter atau status persediaan.
- **Arsitektur Offline-First / Cache-First:** Pola ini wajib diterapkan pada aplikasi yang menggunakan penyimpanan lokal (seperti Hive, SQLite, atau SharedPreferences) di mana data lokal ditampilkan secara instan lalu diperbarui secara asinkron dari API server.

---

## 3. Jawaban Pertanyaan Refleksi Tambahan

### A. Kapan `setState` masih cukup, dan kapan state harus naik ke Riverpod?
- **`setState` Cukup:** Untuk *ephemeral state* (state lokal privat pada 1 widget saja yang tidak dibagikan ke widget lain), contohnya: toggle visibilitas password, animasi UI lokal, atau penanganan nilai sementara `TextEditingController` dalam form dialog.
- **Naik ke Riverpod:** Saat state bersifat *app-wide / shared state* (dibutuhkan oleh beberapa widget/halaman yang terpisah), melibatkan logika bisnis asinkron (API/Database), membutuhkan caching, dependency injection, atau perlu dites secara independen (unit testing) tanpa menggantungkan pada UI.

### B. Apa perbedaan `context.go` dan `context.push`, dan kapan masing-masing tepat digunakan?
- **`context.go` (Declarative / Target Navigation):** Mengubah lokasi URI router dan menyesuaikan tumpukan navigasi (*navigation stack*) sesuai dengan pohon rute GoRouter. Tepat digunakan untuk navigasi antar-menu/tab utama (`/` ke `/stats`), deep-linking, atau pengalihan rute (redirect pasca-login).
- **`context.push` (Imperative Stack Navigation):** Menumpuk rute baru di atas rute saat ini tanpa mengubah tumpukan rute utama. Tepat digunakan untuk rute bertingkat seperti membuka halaman detail dari daftar (`/detail/1`), di mana pengguna mengharapkan tombol *Back* alami untuk kembali ke halaman sebelumnya.

### C. Bagaimana `AsyncValue` mencegah bug dibanding tiga boolean terpisah?
- Menggunakan 3 boolean terpisah (`isLoading`, `hasError`, `isSuccess`) rentan terhadap bug **impossible state** (misalnya `isLoading = true` dan `hasError = true` aktif bersamaan akibat kelalaian meng-update variabel).
- `AsyncValue` menggunakan **Pattern Matching & Sealed Class (Union Types)** yang menjamin bahwa state *hanya* bisa berada pada satu kondisi yang valid (`AsyncLoading`, `AsyncError`, atau `AsyncData`). Penggunaan `.when()` memaksa developer untuk menangani ketiga kondisi tersebut secara eksplisit di compile-time sehingga tidak ada edge-case yang terlewat.

### D. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?
1. **Perbaikan Sinkronisasi pada `widget_test.dart`:**
   - **Perbaikan:** Mengubah `await tester.pump()` menjadi `await tester.pumpAndSettle()` setelah interaksi penambahan tugas pada dialog.
   - **Alasan:** Menunggu hingga animasi dialog tertutup sempurna untuk mencegah error `found 2 widgets` akibat teks yang masih ada di `TextField` dialog.
2. **Perbaikan Assertion Asinkron pada Unit Test `stats_notifier_test.dart`:**
   - **Perbaikan:** Menambahkan `container.listen(...)` dan membaca `container.read(statsProvider)` dengan pembacaan terarah alih-alih langsung mengakses `.future` saat testing kondisi error.
   - **Alasan:** Mencegah Riverpod melempar `ElementWithFuture.dispose` error akibat pembatalan provider asinkron saat exception terjadi di method `build()`.
3. **Refactoring Dekoupling UI pada `TodoPage` & `TodoListNotifier`:**
   - **Perbaikan:** Memisahkan `ListTile` ke widget `TodoTile` dan menambahkan handler `toggleTodo(todo)` / `removeTodo(todo)`.
   - **Alasan:** Memastikan operasi mutasi data tetap akurat berdasarkan rujukan objek `Todo` ketika menggunakan provider turunan hasil filter (`uncompletedTodosProvider`).
