// Ringkasan cakupan dari `coverage/lcov.info`.
//
// Dibuat karena perintah satu-baris untuk menjumlahkan LF/LH berbeda-beda
// antar shell (PowerShell vs cmd), dan versi cmd mudah rusak karena quoting.
// Skrip ini murni Dart tanpa dependensi, jadi jalan di shell apa pun:
//
//   flutter test --coverage
//   dart run tool/coverage_summary.dart
//
// Opsi `--files` menampilkan rincian per berkas, diurutkan dari cakupan
// terendah — berguna untuk memeriksa apakah ada berkas `domain/` yang
// seharusnya teruji tetapi 0%.
import 'dart:io';

void main(List<String> args) {
  final lcov = File('coverage/lcov.info');
  if (!lcov.existsSync()) {
    stderr.writeln(
      'coverage/lcov.info belum ada.\n'
      'Jalankan dulu: flutter test --coverage',
    );
    exitCode = 1;
    return;
  }

  final rows = <({String file, int found, int hit})>[];
  var current = '';
  var lineFound = 0;
  var lineHit = 0;

  for (final line in lcov.readAsLinesSync()) {
    if (line.startsWith('SF:')) {
      current = line.substring(3);
      lineFound = 0;
      lineHit = 0;
    } else if (line.startsWith('LF:')) {
      lineFound = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.startsWith('LH:')) {
      lineHit = int.tryParse(line.substring(3).trim()) ?? 0;
    } else if (line.trim() == 'end_of_record') {
      rows.add((file: current, found: lineFound, hit: lineHit));
    }
  }

  if (rows.isEmpty) {
    stderr.writeln('Tidak ada record di coverage/lcov.info.');
    exitCode = 1;
    return;
  }

  final totalFound = rows.fold<int>(0, (sum, r) => sum + r.found);
  final totalHit = rows.fold<int>(0, (sum, r) => sum + r.hit);
  final percent = totalFound == 0 ? 0.0 : 100 * totalHit / totalFound;

  stdout.writeln('TOTAL: $totalHit/$totalFound baris '
      '= ${percent.toStringAsFixed(1)}%');

  if (args.contains('--files')) {
    final sorted = [...rows]
      ..sort((a, b) => _pct(a).compareTo(_pct(b)));
    stdout
      ..writeln('')
      ..writeln('Per berkas (terendah lebih dulu):');
    for (final row in sorted) {
      final pct = _pct(row).toStringAsFixed(1).padLeft(5);
      final file = row.file
          .replaceAll(r'\', '/')
          .replaceFirst(RegExp(r'^.*/lib/'), 'lib/');
      stdout.writeln('  $pct%  ${row.hit.toString().padLeft(3)}/'
          '${row.found.toString().padLeft(3)}  $file');
    }
  } else {
    stdout.writeln('(tambahkan --files untuk rincian per berkas)');
  }
}

double _pct(({String file, int found, int hit}) row) =>
    row.found == 0 ? 0 : 100 * row.hit / row.found;
