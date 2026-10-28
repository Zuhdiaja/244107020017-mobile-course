import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/push_service.dart';

/// Registration token FCM saat ini, dipakai halaman untuk menampilkan
/// token terpotong. Halaman cukup `ref.watch` — tidak menyentuh
/// `FirebaseMessaging` langsung.
///
/// Di web mengembalikan null: aplikasi ini Android-only untuk FCM
/// (tidak ada FirebaseOptions web), sehingga token memang tidak tersedia.
final fcmTokenProvider = FutureProvider<String?>((ref) {
  if (kIsWeb) return null;
  return getFcmToken();
});
