# Dokumentasi Pengujian & Observasi Offline-First (Minggu 5)

Panduan observasi dan pengujian 3 fitur utama:

---

## 1. Cache-First Read untuk Data API (`GET /posts`)
- **Alur Kerja**:
  1. Buka tab **API Cache-First**.
  2. Data langsung dimuat seketika dari tabel SQLite `cached_posts` tanpa memblokir UI / tanpa layar blank.
  3. Saat aplikasi terhubung ke jaringan (Online), proses background mengambil data terbaru dari endpoint JSONPlaceholder (`https://jsonplaceholder.typicode.com/posts`) lalu memperbarui cache SQLite.
  4. Ketika mode Offline aktif, tab tetap menampilkan data cache yang sudah tersimpan.

---

## 2. Sinkronisasi Catatan Kotor (*Dirty Notes*)
- **Alur Kerja**:
  1. Buat catatan baru melalui tombol **+ (Catatan Baru)**.
  2. Catatan disimpan ke SQLite dengan flag `dirty = true` (Badge warna Amber: `Dirty (Unsynced)`).
  3. Indikator badge pada ikon Sync dan Navigation Bar menunjukkan jumlah catatan yang belum disinkronkan.
  4. Tekan tombol **Sync** pada AppBar:
     - Mensimulasikan pengiriman data dirty ke REST API server (delay 1 detik).
     - Database lokal memperbarui catatan menjadi `dirty = 0` (Badge warna Hijau: `Synced`).
     - Badge dirty berkurang dan kembali ke 0.

---

## 3. Simulasi Offline Deterministik (*Force Offline Mode*)
- **Langkah Observasi**:
  1. **Mode Offline (Sebelum Sync)**:
     - Tekan tombol chip **ONLINE** di kanan atas AppBar atau masuk ke Pengaturan untuk mengaktifkan **Force Offline Mode** (chip berubah menjadi **OFFLINE** merah).
     - Tambah 1 atau 2 catatan baru: Catatan tetap tersimpan di SQLite lokal dan badge dirty bertambah akurat.
     - Tutup dan buka kembali aplikasi: Catatan tetap ada dan status dirty tetap akurat.
     - *Simpan screenshot kondisi ini ke:* `screenshots/01_offline_dirty_notes.png`
  2. **Mode Online & Sinkronisasi (Sesudah Sync)**:
     - Matikan mode offline (kembali ke **ONLINE**).
     - Tekan tombol **Sync**: SnackBar konfirmasi muncul, badge dirty berubah menjadi 0 dan status catatan berubah menjadi `Synced`.
     - *Simpan screenshot kondisi ini ke:* `screenshots/02_synced_notes.png`
     - Buka tab **API Cache-First**: Data cache termuat dan diperbarui dari internet.
     - *Simpan screenshot kondisi ini ke:* `screenshots/03_cache_first_posts.png`
