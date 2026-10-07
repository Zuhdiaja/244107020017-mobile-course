import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

final _local = FlutterLocalNotificationsPlugin();

/// Payload deep link dari klik banner foreground (dibaca saat terminated).
String? pendingDeepLink;

/// Callback navigasi yang dipasang router setelah siap (dipakai saat banner
/// foreground diklik agar langsung pindah ke data.route).
void Function(String route)? _navigate;

void setDeepLinkNavigator(void Function(String route) go) {
  _navigate = go;
}

// Praktikum 2: permission + notifikasi lokal + token lifecycle
Future<bool> requestNotificationPermission() async {
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
    announcement: false,
    carPlay: false,
    criticalAlert: false,
  );
  return settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional;
}

Future<void> initLocalNotifications() async {
  const android = AndroidInitializationSettings('@mipmap/ic_launcher');
  const ios = DarwinInitializationSettings();
  await _local.initialize(
    settings: const InitializationSettings(android: android, iOS: ios),
    onDidReceiveNotificationResponse: (response) {
      // Klik banner foreground -> simpan payload DAN navigasi langsung.
      pendingDeepLink = response.payload;
      final route = response.payload;
      debugPrint('[notif tap] payload=$route');
      if (route != null && route.isNotEmpty) _navigate?.call(route);
    },
  );
}

Future<void> initFcmToken({
  required Future<void> Function(String token) onToken,
}) async {
  // 1. Ambil token saat ini dan kirim ke backend.
  final token = await FirebaseMessaging.instance.getToken();
  if (token != null) await onToken(token);

  // 2. Token bisa berubah (reinstall, clear data, rotasi keamanan).
  //    Listener ini WAJIB ada, jika tidak backend menyimpan token basi.
  FirebaseMessaging.instance.onTokenRefresh.listen(onToken);

  // 3. Langganan topik kampus (mis. semua mahasiswa angkatan).
  await FirebaseMessaging.instance.subscribeToTopic('pengumuman-kampus');
}

/// Berhenti berlangganan topik (dipakai bila pengguna logout / keluar kelas).
Future<void> unsubscribeFromTopic() async {
  await FirebaseMessaging.instance.unsubscribeFromTopic('pengumuman-kampus');
}

// Praktikum 3: background handler + tiga app state + deep link

/// Handler background WAJIB fungsi top-level (berjalan di isolate terpisah),
/// ditandai @pragma('vm:entry-point') agar tidak di-tree-shake di release.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Jangan akses BuildContext / Riverpod di sini.
  // Tugasnya: catat / simpan ringan saja. Navigasi dilakukan saat klik.
  debugPrint('[FCM background] id=${message.messageId} '
      'route=${message.data['route']}');
}

void registerBackgroundHandler() {
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
}

/// Daftarkan handler untuk state foreground & background-klik.
/// [go] adalah fungsi navigasi router (mis. `router.go`).
void listenForeground(void Function(String route) go) {
  // Foreground: sistem TIDAK menampilkan banner otomatis,
  // jadi tampilkan manual via local notification.
  FirebaseMessaging.onMessage.listen((message) async {
    final route = message.data['route'] ?? '/';
    // Diagnostik: lihat isi data payload yang benar-benar diterima.
    debugPrint('[FCM foreground] data=${message.data} route=$route');
    const androidDetails = AndroidNotificationDetails(
      'pengumuman',
      'Pengumuman Kampus',
      channelDescription: 'Notifikasi pengumuman kampus',
      importance: Importance.high,
      priority: Priority.high,
    );
    await _local.show(
      id: message.hashCode,
      title: message.notification?.title ?? 'Pengumuman',
      body: message.notification?.body ?? '',
      notificationDetails: const NotificationDetails(android: androidDetails),
      payload: route,
    );
  });

  // Background -> diklik.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    debugPrint('[FCM opened] data=${message.data}');
    go(message.data['route'] ?? '/');
  });
}

/// Terminated -> aplikasi dibuka dari notifikasi.
Future<void> handleTerminated(void Function(String route) go) async {
  final initial = await FirebaseMessaging.instance.getInitialMessage();
  if (initial != null) go(initial.data['route'] ?? '/');
  if (pendingDeepLink != null) go(pendingDeepLink!);
}
