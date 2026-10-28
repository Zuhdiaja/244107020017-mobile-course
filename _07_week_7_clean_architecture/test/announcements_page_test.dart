import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:week7_clean_architecture/features/announcements/domain/entities/announcement.dart';
import 'package:week7_clean_architecture/features/announcements/presentation/pages/announcements_page.dart';
import 'package:week7_clean_architecture/features/announcements/presentation/providers/announcements_providers.dart';

/// Widget test halaman pencarian pengumuman (Minggu 9).
///
/// Provider repository dioverride dengan daftar tetap sehingga halaman
/// diuji tanpa Firebase, tanpa Dio, tanpa penyimpanan — hanya kontrak
/// provider. Alur yang diuji persis seperti uji manual: mengetik query
/// lalu memeriksa daftar/empty state yang tampil.
List<Announcement> get _sample => [
  Announcement(
    id: '1',
    title: 'Ujian Akhir Semester Ganjil',
    body: 'Ujian digelar 8-19 Desember.',
    date: DateTime(2026, 11, 10),
  ),
  Announcement(
    id: '2',
    title: 'Bebas Laboratorium',
    body: 'Lunasi sebelum ujian akhir.',
    date: DateTime(2026, 11, 5),
  ),
];

Widget _wrap() {
  return ProviderScope(
    overrides: [announcementsProvider.overrideWith((ref) async => _sample)],
    child: const MaterialApp(home: AnnouncementsPage()),
  );
}

/// Varian halaman dengan sumber data kosong — menguji state "belum ada
/// pengumuman sama sekali" (temuan review AI, dibuktikan dengan grep
/// bahwa state ini belum punya test, lalu ditambahkan di sini).
Widget _wrapEmpty() {
  return ProviderScope(
    overrides: [announcementsProvider.overrideWith((ref) async => const [])],
    child: const MaterialApp(home: AnnouncementsPage()),
  );
}

Future<void> _typeQuery(WidgetTester tester, String query) async {
  await tester.enterText(find.byKey(const Key('search-field')), query);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('query kosong menampilkan seluruh pengumuman', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();

    expect(find.text('Ujian Akhir Semester Ganjil'), findsOneWidget);
    expect(find.text('Bebas Laboratorium'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('query cocok memfilter daftar yang tampil', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _typeQuery(tester, 'ujian');

    expect(find.text('Ujian Akhir Semester Ganjil'), findsOneWidget);
    expect(find.text('Bebas Laboratorium'), findsNothing);
  });

  testWidgets('query tak cocok menampilkan empty state', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _typeQuery(tester, 'zzz-tak-ada');

    expect(find.text('Tidak ada pengumuman yang cocok'), findsOneWidget);
    expect(find.text('Coba kata kunci lain, mis. "ujian".'), findsOneWidget);
    expect(find.byIcon(Icons.search_off), findsOneWidget);
  });

  testWidgets('tombol hapus mengembalikan seluruh daftar', (tester) async {
    await tester.pumpWidget(_wrap());
    await tester.pumpAndSettle();
    await _typeQuery(tester, 'zzz-tak-ada');

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(find.text('Ujian Akhir Semester Ganjil'), findsOneWidget);
    expect(find.text('Bebas Laboratorium'), findsOneWidget);
  });

  testWidgets('sumber data kosong menampilkan pesan belum ada pengumuman', (
    tester,
  ) async {
    await tester.pumpWidget(_wrapEmpty());
    await tester.pumpAndSettle();

    expect(find.text('Belum ada pengumuman'), findsOneWidget);
    expect(find.text('Daftar pengumuman masih kosong.'), findsOneWidget);
    expect(find.byIcon(Icons.campaign), findsOneWidget);
  });
}
