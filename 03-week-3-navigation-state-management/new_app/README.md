# new_app

Proyek Flutter untuk Pengujian & Implementasi State Management Menggunakan **Riverpod 2.x**.

---

## Verifikasi Kualitas Kode & State Management

Verifikasi telah dilakukan pada seluruh file kode:

1. **State Immutability:** ✅ Memakai spread operator `[...state]` dan `AsyncValue.guard()`, tidak ada mutasi list langsung (`state.add()`).
2. **Penggunaan `ref.watch` & `ref.read`:** ✅ `ref.watch` hanya di dalam `build()`, `ref.read` & `ref.invalidate` di dalam callback.
3. **Penanganan 3 State AsyncValue:** ✅ `loading`, `error`, dan `success` ditangani sepenuhnya dengan `AsyncValue.when()`.
4. **Tipe Provider:** ✅ Dideklarasikan secara eksplisit (`NotifierProvider` / `AsyncNotifierProvider`) tanpa duplikasi.
5. **API Riverpod Modern:** ✅ Menggunakan `Notifier`, `AsyncNotifier`, dan `ConsumerWidget` (bebas dari antipattern `StateProvider` / `StateNotifierProvider` usang).
6. **Linting & Test:** ✅ `flutter analyze` (**0 issues**) dan `flutter test` (**4/4 tests passed**).

Laporan verifikasi selengkapnya dapat dilihat di [`readme.md`](file:///home/radit/Polinema/radit-firansah-mobile-course/03-week-3-navigation-state-management/readme.md).
