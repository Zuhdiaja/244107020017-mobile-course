# Membangun APK + AAB dengan perintah yang sama seperti CI, lalu memastikan
# kedua berkas benar-benar ada di path yang dirujuk `upload-artifact`.
#
# Kalau path di workflow salah, artefak tidak terunggah dan job CI gagal pada
# step upload. Skrip ini menangkap kesalahan itu tanpa perlu push.
#
# Pemakaian (dari root repository):
#   powershell -ExecutionPolicy Bypass -File _13_week_13_ci_cd_automation\tool\build_artifacts.ps1
#
# Peringatan: build release di project ini masih ditandatangani debug keystore.
# Artefak cocok untuk uji internal, BUKAN untuk diunggah ke Play Store.

$ErrorActionPreference = 'Continue'

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$project = Join-Path $repoRoot '_12_week_12_testing_quality_assurance'

# Path ini HARUS sama dengan blok `path:` pada step "Upload APK + AAB".
$apkPath = Join-Path $project 'build\app\outputs\flutter-apk\app-release.apk'
$aabPath = Join-Path $project 'build\app\outputs\bundle\release\app-release.aab'

# Lihat catatan di check_ci_locally.ps1: PowerShell 5.1 tidak menangkap stderr
# `flutter.bat`, jadi perintah dijalankan lewat cmd dengan keluaran ke berkas.
function Invoke-Build {
    param([string]$Command)

    $log = [System.IO.Path]::GetTempFileName()
    try {
        cmd /c "$Command > `"$log`" 2>&1" | Out-Null
        $code = $LASTEXITCODE
        Get-Content -Path $log -Raw -ErrorAction SilentlyContinue |
            ForEach-Object { Write-Host $_.TrimEnd() }
        return $code
    }
    finally {
        Remove-Item $log -Force -ErrorAction SilentlyContinue
    }
}

Push-Location $project
try {
    Write-Host '==> flutter build apk --release' -ForegroundColor Cyan
    $apkStart = Get-Date
    $apkCode = Invoke-Build 'flutter build apk --release'
    if ($apkCode -ne 0) {
        Write-Host "GAGAL: flutter build apk --release (exit $apkCode)" -ForegroundColor Red
        exit 1
    }
    $apkSeconds = [int]((Get-Date) - $apkStart).TotalSeconds

    Write-Host ''
    Write-Host '==> flutter build appbundle --release' -ForegroundColor Cyan
    $aabStart = Get-Date
    $aabCode = Invoke-Build 'flutter build appbundle --release'
    if ($aabCode -ne 0) {
        Write-Host "GAGAL: flutter build appbundle --release (exit $aabCode)" -ForegroundColor Red
        exit 1
    }
    $aabSeconds = [int]((Get-Date) - $aabStart).TotalSeconds
}
finally {
    Pop-Location
}

$missing = @()
foreach ($p in @($apkPath, $aabPath)) {
    if (-not (Test-Path $p)) { $missing += $p }
}

if ($missing.Count -gt 0) {
    Write-Host ''
    Write-Host 'Path artefak tidak ditemukan. `upload-artifact` akan gagal (if-no-files-found: error):' -ForegroundColor Red
    $missing | ForEach-Object { Write-Host "  - $_" -ForegroundColor Red }
    exit 1
}

$rows = @(
    [pscustomobject]@{
        Berkas   = 'app-release.apk'
        UkuranMB = [math]::Round((Get-Item $apkPath).Length / 1MB, 2)
        Detik    = $apkSeconds
    },
    [pscustomobject]@{
        Berkas   = 'app-release.aab'
        UkuranMB = [math]::Round((Get-Item $aabPath).Length / 1MB, 2)
        Detik    = $aabSeconds
    }
)

Write-Host ''
Write-Host 'Kedua artefak ada di path yang dirujuk workflow:' -ForegroundColor Green
$rows | Format-Table Berkas, UkuranMB, Detik -AutoSize
