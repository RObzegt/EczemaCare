@echo off
REM ===============================================
REM   Gezondheids Tracker Flutter App Launcher
REM ===============================================

SETLOCAL ENABLEDELAYEDEXPANSION

cd /d "%~dp0"

echo.
echo ========================================
echo   Gezondheids Tracker App
echo ========================================
echo.

REM ===============================================
REM Find Flutter
REM ===============================================
echo [1/4] Looking for Flutter...

SET "FLUTTER_CMD="

REM Check parent folder first
IF EXIST "..\flutter\bin\flutter.bat" (
    SET "FLUTTER_CMD=..\flutter\bin\flutter.bat"
    echo       Found: ..\flutter
    goto found
)

REM Check C:\Down\orions2\flutter
IF EXIST "C:\Down\orions2\flutter\bin\flutter.bat" (
    SET "FLUTTER_CMD=C:\Down\orions2\flutter\bin\flutter.bat"
    echo       Found: C:\Down\orions2\flutter
    goto found
)

REM Check if in PATH
where flutter >nul 2>&1
IF !ERRORLEVEL! EQU 0 (
    SET "FLUTTER_CMD=flutter"
    echo       Found: flutter in PATH
    goto found
)

REM Not found
echo [ERROR] Flutter not found!
echo.
echo Please install Flutter or set FLUTTER_HOME
pause
exit /b 1

:found
echo.

REM ===============================================
REM Select Device
REM ===============================================
echo [2/4] Target device...

IF "%~1"=="" (
    SET "DEVICE=chrome"
) ELSE (
    SET "DEVICE=%~1"
)

echo       Using: !DEVICE!
echo.

REM ===============================================
REM Install Dependencies
REM ===============================================
echo [3/4] Installing dependencies...
echo.

call "!FLUTTER_CMD!" pub get

IF !ERRORLEVEL! NEQ 0 (
    echo.
    echo [ERROR] Failed to install dependencies
    pause
    exit /b 1
)

echo.

REM ===============================================
REM Launch App
REM ===============================================
echo [4/4] Launching app in !DEVICE!...
echo.
echo ========================================
echo   App Starting
echo   Press Ctrl+C to stop
echo ========================================
echo.

REM Use fixed web port so localStorage persists between runs
if /i "!DEVICE!"=="chrome" (
    call "!FLUTTER_CMD!" run -d !DEVICE! --web-port=53127 --web-browser-flag="--kiosk"
) else (
    call "!FLUTTER_CMD!" run -d !DEVICE!
)

echo.
echo ========================================
echo   App Closed
echo ========================================
pause
