# Praktikum Minggu 1: "Flutter Hello World"

## 1. Tools dan Ekosistem Flutter

* `flutter doctor` → memastikan instalasi Flutter dan Android tidak bermasalah.
* `flutter devices` → mengecek emulator/perangkat yang terhubung.
* **Hot Reload** → memperbarui kode tanpa menghapus state aplikasi.
* **Hot Restart** → menjalankan ulang aplikasi dan menghapus/reset state.

## 2. Pertanyaan yang perlu dijawab:

1. Kapan native lebih tepat dipilih daripada cross-platform?
2. Bagaimana perubahan state berhubungan dengan widget tree dan UI deklaratif?
3. Mengapa commit kecil dengan pesan jelas bermanfaat bagi pekerjaan tim dan portfolio?

### Jawaban:
* **Native** lebih tepat jika membutuhkan performa maksimal, akses fitur perangkat yang sangat spesifik, atau integrasi platform yang kompleks.
* **State dan widget tree**: Perubahan state membuat Flutter membangun ulang widget yang terkait sehingga UI mengikuti kondisi terbaru secara deklaratif.
* **Commit kecil dan jelas** memudahkan tim memahami perubahan, melacak error, melakukan review, dan menunjukkan proses kerja yang rapi di portfolio.


