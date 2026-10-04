# Output Awal AI (draf mentah, sebelum perbaikan)

Draf pertama yang dihasilkan AI. Beberapa bagian sengaja bermasalah dan
diperbaiki manual (lihat `03-perbaikan-manual.md`).

```dart
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class PushService {
  final _local = FlutterLocalNotificationsPlugin();

  // MASALAH 1: handler background sebagai method kelas -> isolate terpisah
  // tidak menemukan method ini. Harus top-level.
  Future<void> backgroundHandler(RemoteMessage message) async {
    print('Pesan background: ${message.messageId}');
  }

  Future<void> init() async {
    // MASALAH 2: token hanya dicetak, tidak dikirim ke backend.
    final token = await FirebaseMessaging.instance.getToken();
    print('FCM token: $token');

    // MASALAH 3: onTokenRefresh hanya log, backend menyimpan token basi.
    FirebaseMessaging.instance.onTokenRefresh.listen((t) {
      print('Token refresh: $t');
    });

    await FirebaseMessaging.instance.subscribeToTopic('pengumuman kampus'); // MASALAH 4: spasi

    // MASALAH 5: foreground tidak menampilkan local notification.
    FirebaseMessaging.onMessage.listen((message) {
      print('Foreground: ${message.notification?.title}');
    });

    // MASALAH 6: navigasi lewat context di dalam service.
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      // Navigator.of(context).pushNamed(message.data['route']); // context tak tersedia
    });
  }
}
```

Ringkasan masalah pada draf awal:

1. Background handler berupa **method kelas**, bukan fungsi top-level.
2. `getToken` / `onTokenRefresh` hanya `print`, tidak `POST /devices`.
3. Tidak ada local notification untuk state foreground (banner tak muncul).
4. Nama topik memakai spasi (`pengumuman kampus`) — tidak valid.
5. Tidak ada `getInitialMessage()` untuk state terminated.
6. Tidak ada pemisahan platform Android vs iOS.
7. Token di-log penuh (melanggar aturan tidak menampilkan token).
