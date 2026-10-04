# Refleksi

## 1. Mengapa refresh token tidak boleh disimpan di SharedPreferences? Apa risikonya bila bocor?

`SharedPreferences` menyimpan data sebagai file XML/plist biasa di penyimpanan
internal aplikasi, **tanpa enkripsi**. Pada perangkat yang di-root, atau lewat
backup ADB / bug backup, isinya bisa dibaca siapa pun.

Refresh token adalah kredensial berumur panjang: siapa pun yang memegangnya
bisa menukarnya dengan access token baru berulang kali, bahkan setelah access
token kedaluwarsa. Kalau bocor, penyerang bisa menyamar sebagai pengguna dalam
waktu lama tanpa perlu password, dan rotasi access token tidak menolong.

Karena itu token disimpan lewat `flutter_secure_storage`, yang memakai
Keystore (Android) / Keychain (iOS) — terenkripsi dan terikat perangkat.
Praktik tambahan: refresh token hanya dipakai endpoint refresh, dan server
harus mendukung pencabutan (revocation) bila terdeteksi.

## 2. Apa yang rusak bila `onTokenRefresh` diabaikan selama satu semester?

Token FCM berotasi: saat reinstall, clear data, restore backup, atau
rotasi keamanan Google, token lama berhenti valid. Tanpa listener
`onTokenRefresh`, backend menyimpan token basi. Akibatnya, notifikasi ke
perangkat itu **gagal terkirim diam-diam** (FCM mengembalikan error
`UNREGISTERED`/`INVALID_ARGUMENT`), dan karena tidak ada error ke pengguna,
masalah baru terasa setelah mahasiswa mengeluh tidak menerima pengumuman.
Selama satu semester, daftar token di backend perlahan membusuk dan
notifikasi personal/topik makin banyak yang tidak sampai.

## 3. Kapan memakai topik dan kapan memakai token perangkat?

- **Topik** untuk broadcast yang sama ke banyak orang dan tidak rahasia.
  Contoh: `pengumuman-kampus` — "Jadwal UAS semester ini sudah terbit".
- **Token perangkat** untuk pesan personal yang harus sampai ke satu orang.
  Contoh: "Tagihan UKT kamu jatuh tempo 10 Mei" atau "Nilai Mata Kuliah
  Mobile sudah keluar". Token perangkat wajib karena topik tidak bisa
  menargetkan individu.

## 4. Bagian mana dari draf AI yang Anda tolak atau perbaiki, dan mengapa?

Lihat `02-output-awal-ai.md` dan `03-perbaikan-manual.md`. Yang paling
penting:

- **Ditolak:** background handler sebagai method kelas. Handler berjalan di
  isolate terpisah sehingga method kelas tidak bisa diakses — harus fungsi
  top-level dengan `@pragma('vm:entry-point')`.
- **Diperbaiki:** `onTokenRefresh` yang hanya `print` diganti agar benar-benar
  `POST /devices`; nama topik berspasi diperbaiki; local notification
  foreground ditambahkan; `getInitialMessage` ditambahkan untuk state
  terminated; dan token penuh dihapus dari log.
- **Tambahan di luar draf AI:** penjaga `retried` pada interceptor Dio agar
  refresh 401 hanya terjadi **sekali** (draf awal berpotensi loop tak
  berujung bila token hasil refresh tetap ditolak).
