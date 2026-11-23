@echo off
setlocal

REM ===========================================================================
REM Menjalankan aplikasi di Chrome untuk diperiksa MANUAL (klik sendiri).
REM
REM Bedanya dengan tool\run_integration_web.cmd:
REM   - skrip ini TIDAK menjalankan test otomatis
REM   - aplikasi benar-benar berjalan dan bisa Anda klik
REM   - setelah build pertama (~60 detik), simpan perubahan -> hot reload ~2 detik
REM
REM Pemakaian (dari folder project):
REM   tool\run_app_web.cmd
REM
REM Lalu di Chrome, ikuti daftar periksa di README bagian
REM "Cek manual aplikasi".
REM ===========================================================================

set "WEBPORT=5555"
set "ROOT=%~dp0.."

pushd "%ROOT%"
set "ROOT=%CD%"

echo [i] Menjalankan aplikasi di Chrome (port %WEBPORT%)...
echo [i] Build pertama lambat (~60 detik). Setelah itu: simpan file = hot reload.
echo [i] Tekan q di terminal ini untuk berhenti.
echo.

REM Login di aplikasi ini memakai backend mock, jadi tidak butuh
REM google-services.json. Firebase tidak diinisialisasi di web.
flutter run -d chrome --web-port=%WEBPORT%

set "RC=%ERRORLEVEL%"
popd
exit /b %RC%
