# Refleksi Minggu 4: Networking & REST API

### 1. Mengapa UI dilarang memanggil Dio langsung? Apa yang rusak jika aturan ini dilanggar?

UI seharusnya hanya fokus pada rendering tampilan dan menerima input dari user, bukan mengurusi detail jaringan atau parsing data. 

Jika UI langsung memanggil Dio:
- **Kode jadi terikat kuat (tightly coupled):** Jika ada perubahan URL endpoint, query param, atau format header, kita harus mengubah file-file widget satu per satu.
- **Sulit diuji (untestable):** Widget test akan sulit dijalankan karena kita tidak bisa dengan mudah mengganti pemanggilan HTTP asli dengan data tiruan (mock/fake).
- **Duplikasi kode:** Penanganan error jaringan, interceptor, dan mapping JSON akan berulang di banyak tempat.

Dengan adanya Repository layer dan Riverpod, UI cukup mengamati state yang sudah bersih dan terisolasi dari protokol jaringan.

---

### 2. Kapan pagination client-side cukup, dan kapan harus mengandalkan pagination server (_page/_limit)?

- **Client-side pagination cukup** jika total data dari server jumlahnya sedikit dan ukurannya kecil (misalnya hanya 20–50 item, seperti daftar kategori atau opsi dropdown). Data diambil sekali di awal, lalu dibagi per halaman langsung di memori aplikasi.
- **Server-side pagination wajib digunakan** jika data berpotensi tumbuh banyak (ratusan hingga ribuan item, seperti postingan, komentar, atau katalog produk). Mengambil semua data sekaligus akan membuat loading awal sangat lama, boros kuota internet, dan membebani memori perangkat. Parameter `_page` dan `_limit` memastikan perangkat hanya meminta data yang memang sedang dilihat user.

---

### 3. Bagaimana exception repository berubah menjadi AsyncError tanpa try/catch di setiap widget? Kapan try/catch eksplisit tetap dibutuhkan?

Pada Riverpod, method asinkron di dalam Notifier (seperti method `build()` pada `AsyncNotifier`) bekerja secara deklaratif. Jika terjadi exception di repository, Riverpod secara otomatis menangkap error tersebut dan mengubah state menjadi `AsyncError(error, stackTrace)`. Di sisi UI, kita tidak perlu menulis blok try/catch, cukup membaca state lewat `ref.watch()`.

**Try/catch eksplisit tetap dibutuhkan ketika:**
- Menjalankan aksi yang dipicu interaksi user (event handler), seperti menekan tombol submit form, update data, atau delete.
- Kita perlu melakukan fallback khusus atau logging lokal sebelum state diubah.

---

### 4. Bagian mana dari hasil AI yang Anda perbaiki, dan mengapa?

- **Struktur Notifier Riverpod:** Kode awal dari AI sempat menggunakan class yang kurang sesuai dengan versi Riverpod di project. Saya merapikannya menjadi `Notifier` dan `AsyncNotifier` standar agar kodenya lebih sederhana, mudah dibaca, dan tidak overcomplicate.
- **Penambahan Edge Cases di Unit Test:** Hasil test awal AI hanya menguji happy path dan field hilang biasa. Saya menambahkan pengujian untuk map JSON kosong `{}` dan kasus saat backend mengirim angka dalam bentuk pecahan/float (misal `2.0`) agar parsing ke integer tidak memicu runtime error.
- **Isolasi Widget Test:** Saya menambahkan `FakePostRepository` pada widget test agar pengujian antarmuka tidak memicu timer jaringan Dio yang menggantung saat widget di-dispose.
