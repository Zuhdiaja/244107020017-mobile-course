import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/push_service.dart';

/// Registration token FCM saat ini, dipakai halaman untuk menampilkan
/// token terpotong. Halaman cukup `ref.watch` — tidak menyentuh
/// `FirebaseMessaging` langsung.
final fcmTokenProvider = FutureProvider<String?>((ref) {
  return getFcmToken();
});
