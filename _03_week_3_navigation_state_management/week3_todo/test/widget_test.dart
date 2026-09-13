import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:week3_todo/providers/stats_provider.dart';

class FakeStatsNotifier extends StatsNotifier {
  @override
  Future<List<String>> build() async {
    return [
      'Total Pengguna: 1.250',
      'Pengguna Aktif: 875',
      'Transaksi Hari Ini: 342',
    ];
  }
}

void main() {
  test('StatsNotifier menghasilkan 3 data statistik', () async {
    final container = ProviderContainer(
      overrides: [
        statsProvider.overrideWith(
          () => FakeStatsNotifier(),
        ),
      ],
    );

    addTearDown(container.dispose);

    final result =
        await container.read(statsProvider.future);

    expect(result, isA<List<String>>());
    expect(result.length, 3);
    expect(
      result[0],
      'Total Pengguna: 1.250',
    );
    expect(
      result[1],
      'Pengguna Aktif: 875',
    );
    expect(
      result[2],
      'Transaksi Hari Ini: 342',
    );
  });
}