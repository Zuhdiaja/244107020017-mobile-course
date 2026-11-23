# Menjalankan pemeriksaan yang SAMA PERSIS dengan .github/workflows/flutter-ci.yml.
#
# Tujuan: kegagalan ditemukan di laptop, bukan setelah push. Kalau skrip ini
# hijau tapi CI merah, berarti ada perbedaan lingkungan (versi Flutter, JDK,
# atau berkas yang tidak ikut ter-commit) - bukan perbedaan perintah.
#
# Pemakaian (dari root repository):
#   powershell -ExecutionPolicy Bypass -File _13_week_13_ci_cd_automation\tool\check_ci_locally.ps1
#
# Keluar dengan kode 1 pada pemeriksaan pertama yang gagal, sama seperti job CI.

$ErrorActionPreference = 'Continue'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$project = Join-Path $repoRoot '_12_week_12_testing_quality_assurance'

if (-not (Test-Path $project)) {
    Write-Host "Project tidak ditemukan: $project" -ForegroundColor Red
    exit 1
}

# Perintah dijalankan lewat cmd /c dengan stderr digabung ke berkas sementara.
#
# Alasannya bukan selera: `flutter` di Windows adalah berkas .bat, dan
# PowerShell 5.1 TIDAK menangkap stderr proses .bat lewat `2>&1`. Akibatnya
# pesan penting (mis. "requires symlink support") hilang, dan exit code bisa
# terbaca 0 padahal perintah gagal. Lewat cmd, keduanya terbaca benar.
function Invoke-CiStep {
    param([string]$Command)

    $log = [System.IO.Path]::GetTempFileName()
    try {
        cmd /c "$Command > `"$log`" 2>&1" | Out-Null
        $code = $LASTEXITCODE
        $text = Get-Content -Path $log -Raw -ErrorAction SilentlyContinue
        if ($text) { Write-Host $text.TrimEnd() }
        return [pscustomobject]@{ Code = $code; Text = $text }
    }
    finally {
        Remove-Item $log -Force -ErrorAction SilentlyContinue
    }
}

Push-Location $project
try {
    # Daftar langkah = daftar step di workflow, urutannya juga sama.
    $steps = @(
        @{ Name = 'flutter pub get'; Command = 'flutter pub get' },
        @{ Name = 'dart format'; Command = 'dart format --output=none --set-exit-if-changed lib test integration_test test_driver' },
        @{ Name = 'flutter analyze --fatal-infos'; Command = 'flutter analyze --fatal-infos' },
        @{ Name = 'flutter test --coverage'; Command = 'flutter test --coverage' },
        @{ Name = 'ringkasan cakupan'; Command = 'dart run tool/coverage_summary.dart' }
    )

    $results = @()
    foreach ($step in $steps) {
        Write-Host ''
        Write-Host "==> $($step.Name)" -ForegroundColor Cyan
        $started = Get-Date
        $result = Invoke-CiStep $step.Command
        $code = $result.Code
        $seconds = [int]((Get-Date) - $started).TotalSeconds

        # Satu pengecualian, sempit dan terdokumentasi:
        # Di Windows TANPA Developer Mode, `flutter pub get` menyelesaikan
        # resolusi paket ("Got dependencies!") lalu gagal HANYA pada pembuatan
        # symlink plugin untuk platform desktop. Project ini targetnya Android,
        # dan `flutter test` maupun `flutter build apk` tidak memerlukan symlink
        # tersebut. Run kedua berhasil karena .dart_tool sudah ada.
        # Runner CI memakai ubuntu-latest dan tidak pernah terkena ini.
        $symlinkLimitation =
            $code -ne 0 -and
            $result.Text -match 'requires symlink support' -and
            (Test-Path (Join-Path (Get-Location) '.dart_tool\package_config.json'))

        if ($symlinkLimitation) {
            Write-Host ''
            Write-Host 'CATATAN: gagal hanya pada symlink plugin desktop (butuh Developer Mode Windows).' -ForegroundColor Yellow
            Write-Host 'Paket sudah ter-resolve; langkah berikutnya tidak memerlukan symlink itu.' -ForegroundColor Yellow
            Write-Host 'CI berjalan di ubuntu-latest, jadi tidak terkena batasan ini.' -ForegroundColor DarkGray
            $code = 0
            $note = 'lulus (batasan symlink Windows)'
        }
        else {
            $note = ''
        }

        $results += [pscustomobject]@{
            Langkah = $step.Name
            Hasil   = if ($code -eq 0) { 'LULUS' } else { 'GAGAL' }
            Detik   = $seconds
            Catatan = $note
        }

        if ($code -ne 0) {
            Write-Host ''
            Write-Host "GAGAL pada langkah: $($step.Name) (exit $code)" -ForegroundColor Red
            Write-Host 'CI akan menolak commit ini. Perbaiki dulu, jangan menghapus pemeriksaannya.' -ForegroundColor Yellow
            $results | Format-Table -AutoSize
            exit 1
        }
    }

    Write-Host ''
    Write-Host 'Semua pemeriksaan CI lulus di mesin ini.' -ForegroundColor Green
    $results | Format-Table -AutoSize

    # Build TIDAK dijalankan di sini: butuh beberapa menit dan Gradle.
    # Pakai build_artifacts.ps1 untuk itu.
    Write-Host 'Langkah build: jalankan build_artifacts.ps1' -ForegroundColor DarkGray
}
finally {
    Pop-Location
}
