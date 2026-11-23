import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week12_testing_quality_assurance/features/announcements/presentation/pages/announcement_page.dart';

/// Widget test halaman tujuan deep link `/pengumuman/:id`.
///
/// Halaman ini tidak punya state atau dependensi, sehingga cukup diuji
/// sebagai widget tunggal: id dari rute harus tampil apa adanya.
void main() {
  testWidgets('menampilkan id pengumuman dari parameter', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: AnnouncementPage(id: '3')));

    expect(find.text('Pengumuman #3'), findsOneWidget);
    expect(find.text('Pengumuman #1'), findsNothing);
    expect(find.byIcon(Icons.campaign), findsOneWidget);
  });

  testWidgets('menjelaskan asal halaman (deep link payload FCM)', (
    tester,
  ) async {
    await tester.pumpWidget(const MaterialApp(home: AnnouncementPage(id: '1')));

    expect(find.textContaining('deep link'), findsOneWidget);
    expect(find.textContaining('FCM'), findsOneWidget);
  });
}
