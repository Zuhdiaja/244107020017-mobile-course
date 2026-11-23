@echo off
setlocal enabledelayedexpansion

REM ===========================================================================
REM Menjalankan integration test di Chrome lewat jalur web-server.
REM
REM Ditulis sebagai .cmd karena perintah lanjutan-baris berbeda antar shell:
REM PowerShell memakai backtick ( ` ), sedangkan cmd memakai caret ( ^ ).
REM Skrip ini menghindari keduanya dengan menulis perintah dalam satu baris.
REM
REM Pemakaian (dari folder project):
REM   tool\run_integration_web.cmd
REM
REM Urutan yang dilakukan:
REM   1. mencari chromedriver (variabel CHROMEDRIVER, PATH, lalu tool\)
REM   2. menyalakan ChromeDriver di port 4444
REM   3. menjalankan flutter drive -d web-server
REM   4. mematikan ChromeDriver lagi
REM ===========================================================================

set "PORT=4444"
set "WEBPORT=5555"
set "ROOT=%~dp0.."
REM Rapikan path: buang `\tool\..` agar yang dicetak path yang wajar.
pushd "%ROOT%"
set "ROOT=%CD%"
popd

REM --- 1) Cari chromedriver -------------------------------------------------
set "DRIVER="
if defined CHROMEDRIVER if exist "%CHROMEDRIVER%" set "DRIVER=%CHROMEDRIVER%"

if not defined DRIVER (
  for /f "delims=" %%i in ('where chromedriver 2^>nul') do (
    if not defined DRIVER set "DRIVER=%%i"
  )
)

if not defined DRIVER if exist "%ROOT%\tool\chromedriver.exe" set "DRIVER=%ROOT%\tool\chromedriver.exe"

if not defined DRIVER (
  echo.
  echo [X] chromedriver tidak ditemukan.
  echo.
  echo     Cara memasang, pilih salah satu:
  echo.
  echo     1. Taruh chromedriver.exe di folder tool\ project ini:
  echo          %ROOT%\tool\chromedriver.exe
  echo.
  echo     2. Tambahkan folder chromedriver ke PATH Windows.
  echo.
  echo     3. Set variabel CHROMEDRIVER ke path lengkap file itu:
  echo          set CHROMEDRIVER=C:\path\ke\chromedriver.exe
  echo.
  echo     Unduh versi yang SAMA dengan Chrome Anda di:
  echo       https://googlechromelabs.github.io/chrome-for-testing/
  echo     Cek versi Chrome: buka chrome://version
  echo.
  exit /b 1
)

echo [1/3] ChromeDriver: %DRIVER%

REM --- 2) Nyalakan ChromeDriver --------------------------------------------
start "chromedriver-%PORT%" /min "%DRIVER%" --port=%PORT%

REM Beri waktu ChromeDriver siap menerima koneksi.
REM `timeout` gagal bila stdin bukan konsol (mis. dijalankan dari skrip lain),
REM jadi dipakai `ping` sebagai jeda yang aman di semua kondisi.
ping -n 4 127.0.0.1 >nul

REM --- 3) Jalankan integration test ----------------------------------------
echo [2/3] Menjalankan integration test di Chrome (web-server port %WEBPORT%)...
echo.

pushd "%ROOT%"
flutter drive -d web-server --web-port=%WEBPORT% --driver=test_driver/integration_test.dart --target=integration_test/app_test.dart
set "RC=%ERRORLEVEL%"
popd

REM --- 4) Bersihkan --------------------------------------------------------
taskkill /IM chromedriver.exe /F >nul 2>&1
echo.
if "%RC%"=="0" (
  echo [3/3] Selesai: integration test LULUS.
) else (
  echo [3/3] Selesai: integration test GAGAL ^(kode %RC%^).
)
exit /b %RC%
