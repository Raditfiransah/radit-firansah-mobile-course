import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final _local = FlutterLocalNotificationsPlugin();

// Token FCM untuk halaman Debug (ditampilkan terpotong).
final fcmTokenProvider =
    FutureProvider<String?>((ref) => FirebaseMessaging.instance.getToken());

// Parsing rute dari payload data. Dipisah agar bisa diuji tanpa Firebase.
String routeFromData(Map<String, dynamic> data) =>
    data['route'] as String? ?? '/';

const _channel = AndroidNotificationChannel(
  'pengumuman_kampus',
  'Pengumuman Kampus',
  importance: Importance.high,
);

Future<bool> requestNotificationPermission() async {
  // [ANDROID 13+ / iOS] Keduanya wajib izin runtime. Di Android <13 izin
  // otomatis granted saat install; iOS selalu lewat dialog.
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    // [iOS saja] announcement & carPlay tidak berlaku di Android.
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

Future<void> initLocalNotifications() async {
  // [BERBEDA] Android pakai channel + ikon mipmap; iOS pakai Darwin settings
  // dan tidak punya konsep channel.
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      // Klik banner foreground -> teruskan payload ke router.
      pendingDeepLink = response.payload;
      final route = response.payload;
      if (route != null) onDeepLink?.call(route);
    },
  );
  // [ANDROID SAJA] Channel wajib dibuat agar notifikasi Android 8+ muncul.
  // iOS tidak memerlukan ini.
  await _local
      .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>()
      ?.createNotificationChannel(_channel);
}

String? pendingDeepLink;
void Function(String route)? onDeepLink;

// [ISOLATE TERPISAH] Fungsi WAJIB top-level (bukan method kelas) dan
// ber-@pragma('vm:entry-point'). Di sini TIDAK BOLEH akses BuildContext,
// Riverpod, atau widget apa pun. Tugasnya hanya menyimpan data ringan.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Jangan akses BuildContext / Riverpod di sini.
  // Tugasnya: catat / simpan ringan saja. Navigasi dilakukan saat klik.
  pendingDeepLink = routeFromData(message.data);
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

Future<void> initFcmToken(
    {required Future<void> Function(String token) onToken}) async {
  // 1. Ambil token saat ini dan kirim ke backend.
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  // 2. Token bisa berubah (reinstall, clear data, rotasi keamanan).
  //    Listener ini WAJIB ada, jika tidak backend menyimpan token basi.
  //    onTokenRefresh harus benar-benar mengirim ke backend (bukan sekadar log).
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  // 3. Langganan topik kampus (mis. semua mahasiswa angkatan).
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

// Foreground: [ANDROID] sistem TIDAK menampilkan banner otomatis,
// jadi tampilkan manual via local notification. [iOS] FCM menampilkan
// banner sendiri saat foreground, jadi ini hanya dipakai Android.
void listenForeground(void Function(String route) go) {
  FirebaseMessaging.onMessage.listen((message) async {
    final route = routeFromData(message.data);
    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: route,
    );
  });

  // Background -> diklik.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    go(message.data['route'] ?? '/');
  });
}

Future<void> handleTerminated(void Function(String route) go) async {
  // Terminated -> dibuka dari notifikasi.
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(initial.data['route'] ?? '/');
  if (pendingDeepLink != null) go(pendingDeepLink!);
}

Future<void> unsubscribeFromTopic(String topic) =>
    FirebaseMessaging.instance.unsubscribeFromTopic(topic);
