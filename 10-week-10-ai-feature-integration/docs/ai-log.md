# AI Log — Fitur Chat AI (Minggu 10)

Dokumen ini memenuhi syarat codelab Minggu 10: **system prompt, user prompt,
output awal AI**, cara verifikasi, dan keputusan yang diambil. Ditulis apa
adanya, termasuk bagian yang salah dan harus diperbaiki.

> **Catatan kejujuran:** "AI" di sini adalah asisten yang sama dengan penulis
> kode. Draft awal dihasilkan apa adanya lalu diverifikasi lewat `flutter
> analyze`, test, dan uji manual di Chrome — bukan hasil tempel mentah.

---

## 1. Prompt (5 slot)

```text
Peran: senior Flutter developer.

Konteks:
- Project: week5_offline_notes (hasil Minggu 5), disalin ke folder Minggu 10.
  Riverpod 2.6 (Notifier/AsyncNotifier), GoRouter 18, sqflite, dio, http.
- Sudah ada forceOfflineProvider (Notifier<bool>) untuk simulasi offline.
- Target: satu fitur AI saja, yaitu chat asisten kampus dengan streaming.
- Codelab meminta: API key di flutter_secure_storage, prompt design, OCR/STT/
  Vision (pilih satu), tabel risiko, fallback, flutter analyze + test hijau.

Tugas: integrasikan chat AI Gemini ke project itu, tanpa merombak arsitektur.

Batas:
- Key tidak boleh ada di source, repo, atau log.
- Tanpa dependency baru selain flutter_secure_storage.
- Jangan kirim isi catatan pengguna ke AI API.
- Harus bisa diuji tanpa memanggil jaringan sungguhan.

Output: kode + test + cara uji.
```

Konteks yang **tidak** disertakan: token, API key, isi database pengguna.

---

## 2. Output awal AI (draft pertama)

Draft pertama mengikuti contoh codelab apa adanya:

```dart
class AiService {
  final _storage = const FlutterSecureStorage();
  final _apiUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-pro:generateContent';

  Future<String> ask(String question) async {
    final apiKey = await _storage.read(key: 'ai_api_key');
    ...
    final response = await http.post(Uri.parse('$_apiUrl?key=$apiKey'), ...);
    return data['candidates'][0]['content']['parts'][0]['text'];
  }
}
```

Tiga masalah yang ditemukan saat verifikasi:

| # | Masalah | Bukti |
| :--- | :--- | :--- |
| 1 | `gemini-pro` sudah tidak tersedia di `v1beta`; request akan gagal 404/400 | dicocokkan dengan dokumentasi Gemini API, bukan ditebak |
| 2 | Tidak ada streaming — codelab sendiri meminta "streaming response" di Langkah 3 | `ask()` mengembalikan `String` utuh, UI hanya bisa loading-lalu-muncul |
| 3 | `FlutterSecureStorage` di-hardcode di dalam service → tidak bisa diuji tanpa platform channel | `flutter test` akan gagal di environment tanpa plugin |

---

## 3. Perbaikan dan alasan

| Keputusan | Alasan |
| :--- | :--- |
| `streamGenerateContent` + `alt=sse`, parsing per baris `data: {...}` | Jawaban tampil bertahap; parsing dipisah jadi `parseSseLine` statis supaya bisa diuji tanpa jaringan. |
| Model `gemini-2.5-flash` | Nama model lama tidak tersedia; flash cukup untuk tanya-jawab singkat dan lebih murah. |
| `ApiKeyStore` abstrak + `SecureApiKeyStore` | Service bisa diuji dengan store in-memory; key tetap hanya di secure storage di produksi. |
| `RateLimiter` 20 request/hari | Mitigasi biaya yang diminta tabel risiko; disimpan di `shared_preferences`. |
| `history` dikirim ulang tiap request | Tanpa ini AI lupa konteks pertanyaan sebelumnya. |
| Cek `forceOfflineProvider` sebelum request | Memakai state offline yang sudah ada dari Minggu 5, bukan membuat flag baru. |
| `maxOutputTokens: 512`, `temperature: 0.4` | Batasi biaya dan kurangi jawaban melebar. |

---

## 4. Verifikasi (6 langkah)

1. **`flutter pub get`** → `flutter_secure_storage 9.2.4` terpasang.
2. **`flutter analyze`** → awalnya 2 temuan nyata:

   ```text
   info • Use an initializing formal ... prefer_initializing_formals
          • lib/ai/ai_service.dart:39:8
   warning • Unused import: '../ai/rate_limiter.dart'
          • lib/providers/ai_providers.dart:5:8
   ```

   Diperbaiki: field `keyStore` jadi `required this.keyStore`, import dihapus.
   Hasil akhir: **No issues found!**

3. **`flutter test`** → 13 test lulus. Test yang menutup jalur AI:
   - `parseSseLine` menerima chunk valid, menolak `[DONE]`, baris non-`data:`,
     JSON rusak, dan payload tanpa `candidates`.
   - `askStream` dengan `MockClient` → chunk tergabung, `systemInstruction`
     benar-benar terkirim di body.
   - Tanpa key → `AiException` "API key belum diatur".
   - Status 429 → pesan kuota, bukan exception mentah.
   - `RateLimiter` menolak permintaan ke-3 saat `dailyLimit: 2`.
   - Widget: kirim pesan → bubble user + jawaban tampil; error → banner +
     tombol "Coba lagi"; mode offline → request tidak dipanggil sama sekali.
4. **`dart format --set-exit-if-changed .`** → exit 0.
5. **`flutter build web --release`** → `✓ Built build/web`.
6. **Uji manual di Chrome** (`python3 -m http.server` + Playwright):
   - Buka `/#/chat` → empty state tampil dengan peringatan privasi.
   - Kirim pesan tanpa key → banner "API key belum diatur" + tombol Coba
     lagi/Pengaturan.
   - Simpan key **palsu** lewat Pengaturan → status berubah "Tersimpan di
     secure storage".
   - Kirim pesan lagi → banner "API key ditolak. Periksa kembali key Gemini di
     Pengaturan." → membuktikan request benar-benar keluar ke Google dan error
     HTTP dipetakan, bukan tertelan.

---

## 5. Temuan tambahan (jujur)

- **`sqflite_sw.js` tidak ada di build web** (error console saat build web
  dijalankan). Ini bawaan setup web Minggu 5 (`sqflite_common_ffi_web` butuh
  binary worker yang tidak ikut ter-build), **bukan** akibat fitur AI. Tab
  Catatan/Posts di web tidak bisa dipakai sampai binary itu disiapkan; alur
  chat tidak terpengaruh.
- **Screenshot jawaban AI sukses tidak bisa dibuat** karena tidak ada API key
  valid di environment ini. Jalur sukses ditutup unit test + widget test.
- **`shared_preferences` bisa dihapus user**, jadi rate limit perangkat bukan
  kontrol biaya yang kuat. Untuk produksi, batas harus di backend.
- **Key di klien tetap bisa diekstrak.** Pola aman: proxy backend.

---

## 6. Refleksi

- **Fitur yang dipilih:** chat, karena mencakup prompt design, streaming,
  privasi, biaya, dan fallback sekaligus — bukan sekadar memanggil API.
- **Privasi:** isi catatan tidak pernah dikirim; system prompt melarang meminta
  data pribadi; key di secure storage dan tidak pernah di-log.
- **Fallback:** pesan per status code, tombol coba lagi, dan penolakan cepat
  saat mode offline — bukan menunggu timeout 30 detik.
- **Pelajaran UX:** streaming mengubah persepsi lambat; indikator "..." pada
  bubble kosong membuat aplikasi terasa hidup, dan tombol kirim harus nonaktif
  selama streaming agar tidak ada request ganda.
