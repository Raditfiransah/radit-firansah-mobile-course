# AI Challenge: Perbandingan Solusi Local Storage & Offline-First

Dokumen ini berisi hasil analisis perbandingan teknologi *local storage* di Flutter untuk kebutuhan **CRUD Catatan** dan **Preferensi Tema**, diikuti dengan **AI Verification Checklist** sesuai rubrik evaluasi.

---

## 1. AI Prompt Challenge

### Prompt yang Diberikan:
> "Aplikasi Flutter Offline Notes: CRUD catatan + preferensi tema.
> Bandingkan SharedPreferences, Hive, sqflite (SQLite), dan Drift untuk dua kebutuhan ini. Requirements:
> - Kriteria: kompleksitas query, kebutuhan relasi, reaktivitas (stream), type-safety, ukuran boilerplate, dan kemudahan testing.
> - Beri rekomendasi final: mana untuk preferensi, mana untuk catatan, beserta alasannya dalam 1 tabel.
> - Tunjukkan skema tabel/kotak untuk 1000+ catatan.
> Jelaskan trade-off setiap pilihan."

---

### A. Tabel Perbandingan 4 Solusi Storage

| Kriteria | SharedPreferences | Hive | sqflite (SQLite) | Drift (Moor) |
| :--- | :--- | :--- | :--- | :--- |
| **Model Data** | Key-Value primitif (XML/NSUserDefaults) | NoSQL Key-Value / Box biner | Relasional SQL murni | Relasional SQL bertipe (*Type-safe ORM*) |
| **Kompleksitas Query** | Sangat rendah (hanya `get/set` by key) | Rendah–Sedang (filter loop in-memory) | **Sangat Tinggi** (SQL lengkap, WHERE, ORDER, LIMIT, JOIN) | **Sangat Tinggi** (SQL & Dart Fluent API, JOIN, custom query) |
| **Kebutuhan Relasi** | Tidak mendukung | Manual via HiveList / NoSQL nesting | **Native SQL Foreign Keys** | **Native SQL Foreign Keys & Relasi Type-Safe** |
| **Reaktivitas (Stream)** | Tidak ada (manual polling / State Management) | Ada (`ValueListenable`, `watch()`) | Tidak bawaan (manual invalidate di provider/bloc) | **Native Stream bawaan** (`select().watch()`) |
| **Type-Safety** | Lemah (casting tipe dasar) | Sedang (perlu TypeAdapter manual/codegen) | Lemah (Map<String, Object?>, raw query) | **Sangat Kuat** (Compile-time checked Dart classes) |
| **Ukuran Boilerplate** | **Minimal** (Langsung pakai) | Sedang (Buat model + TypeAdapter + register) | Sedang (Tulis raw SQL migration & `toMap`/`fromMap`) | **Tinggi** (Perlu `build_runner`, file `.drift`/DSL, codegen) |
| **Kemudahan Testing** | Sangat mudah (`setMockInitialValues`) | Mudah (`Hive.init` di memory/temp dir) | Perlu `sqflite_common_ffi` untuk unit test | Sangat mudah (`NativeDatabase.memory()`) |

---

### B. Rekomendasi Final

| Kebutuhan | Teknologi Terpilih | Alasan Utama |
| :--- | :--- | :--- |
| **Preferensi Tema (Dark Mode, Last Opened)** | **SharedPreferences** | Ringan, sederhana, tanpa overhead database. Cocok untuk data skalar (boolean, string timestamp) yang dibaca saat aplikasi pertama kali boot. |
| **CRUD Catatan & Cache API** | **sqflite (SQLite) / Drift** | Mendukung pengurutan (`ORDER BY updated_at DESC`), filtering data kotor (`WHERE dirty = 1`), serta skema relasional terstruktur untuk ribuan catatan & cache payload API. |

---

### C. Skema Penyimpanan untuk 1000+ Catatan (Optimized with Index & Sync Queue)

Untuk menangani 1.000+ catatan dengan performa tinggi dan dukungan offline sync, skema SQLite dirancang sebagai berikut:

```sql
-- 1. Tabel Utama Catatan
CREATE TABLE notes (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    title TEXT NOT NULL,
    body TEXT NOT NULL DEFAULT '',
    updated_at TEXT NOT NULL,          -- Format ISO8601 (UTC) untuk perbandingan versi
    dirty INTEGER NOT NULL DEFAULT 0   -- 1 = belum sinkron ke server, 0 = bersih/synced
);

-- 2. Index untuk Mempercepat Query List & Filter Dirty Notes (1000+ data)
CREATE INDEX idx_notes_updated_at ON notes(updated_at DESC);
CREATE INDEX idx_notes_dirty ON notes(dirty) WHERE dirty = 1;

-- 3. Tabel Cache API (Cache-First Read)
CREATE TABLE cached_posts (
    id INTEGER PRIMARY KEY,
    payload TEXT NOT NULL,             -- JSON encoded payload dari API
    cached_at TEXT NOT NULL
);
```

---

### D. Trade-off Setiap Pilihan

1. **SharedPreferences**:
   - *Kelebihan*: Zero setup, akses instan untuk preferensi sederhana.
   - *Kekurangan*: Tidak cocok untuk data koleksi/catatan. Jika menyimpan ribuan catatan dalam bentuk JSON string tunggal, proses serialize/deserialize akan memblokir UI thread dan boros RAM.
2. **Hive**:
   - *Kelebihan*: Sangat cepat (seluruh index/data berada di memori), sintaks NoSQL ringkas.
   - *Kekurangan*: Tidak memiliki query SQL relasional. Pengurutan dan filtering parsial pada ribuan data memakan memory besar.
3. **sqflite (SQLite)**:
   - *Kelebihan*: Standar industri, performa query/index cepat pada jutaan baris, minim dependency build-tooling.
   - *Kekurangan*: Tidak ada type-safety bawaan untuk query SQL (raw string), error query baru diketahui saat runtime.
4. **Drift**:
   - *Kelebihan*: Compile-time type-safety, auto-generated queries, native reactive stream `watch()`.
   - *Kekurangan*: Mengharuskan `build_runner` code generation yang memperlambat build time development.

---

## 2. AI Verification Checklist

Berikut adalah verifikasi kritis terhadap solusi yang dirancang:

### 1. Apakah AI menempatkan daftar catatan di SharedPreferences?
> **Hasil Verifikasi**: **DITOLAK / TIDAK.**
> - **Justifikasi**: SharedPreferences hanya digunakan untuk menyimpan `dark_mode` (boolean) dan `last_opened_at` (timestamp string).
> - Menempatkan daftar catatan di SharedPreferences adalah *anti-pattern* yang rapuh karena tidak mendukung indexing, atomic transaction, atau query parsial (`WHERE`, `LIMIT`). Seluruh koleksi catatan ditempatkan pada **SQLite (`sqflite`)**.

---

### 2. Apakah skema AI mendukung antrean sync (`dirty flag` / `updated_at`) atau hanya CRUD polos?
> **Hasil Verifikasi**: **YA, MENDUKUNG ANTREAN SYNC LENGKAP.**
> - Skema database memiliki kolom `dirty INTEGER NOT NULL DEFAULT 0` dan `updated_at TEXT NOT NULL`.
> - Setiap catatan yang dibuat/diedit secara offline otomatis ditandai `dirty = 1`.
> - Mekanisme `syncNotes()` menggunakan query `SELECT COUNT(*) WHERE dirty = 1` dan mengubahnya menjadi `dirty = 0` via `markAllSynced()` setelah sinkronisasi berhasil.

---

### 3. Apakah klaim "real-time" AI didukung stream (Drift/watch) atau hanya asumsi?
> **Hasil Verifikasi**: **VALID SECARA STATE MANAGEMENT (RIVERPOD INVALIDATION).**
> - Pada `sqflite`, SQLite tidak memiliki stream native bawaan. Oleh karena itu, reaktivitas dicapai secara deterministik menggunakan **Riverpod `AsyncNotifier`** dengan memanggil `ref.invalidateSelf()` setiap kali ada mutasi data lokal atau background sync.
> - Pada saat data cache API berhasil di-refresh di latar belakang, callback `onBackgroundUpdated` mengeksekusi `ref.invalidateSelf()` sehingga UI terupdate seketika tanpa reload manual.

---

### 4. Apakah estimasi boilerplate AI masuk akal setelah mencoba instalasi?
> **Hasil Verifikasi**: **YA, SANGAT MASUK AKAL.**
> - Menggunakan `sqflite` + `shared_preferences` + `flutter_riverpod` tidak memerlukan code generator `build_runner`, sehingga instalasi `flutter pub add` langsung siap dijalankan tanpa jeda kompilasi codegen yang lama.
> - Penggunaan SQLite wrapper sederhana di `db.dart` memberikan keseimbangan terbaik antara ukuran kode dan kecepatan pengembangan untuk level beginner.

---

### 5. Keputusan Final & Kesimpulan
- **Preferensi**: `SharedPreferences` via `PrefsRepository` (untuk Dark Mode & Last Opened).
- **Catatan & Cache API**: `SQLite (sqflite)` via `NoteRepository` dan `PostRepository` dengan tabel `notes` dan `cached_posts`.
- **State Management**: `flutter_riverpod` (`AsyncNotifier` & `Notifier`) untuk mengelola status `forceOffline`, reaktivitas data cache-first, dan indikator dirty badge.
