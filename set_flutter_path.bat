@echo off
REM ===============================================
REM   Set Flutter Path Helper
REM ===============================================
REM This script helps you set the FLUTTER_HOME
REM environment variable so start_app.bat can
REM find Flutter automatically.
REM ===============================================

echo.
echo ========================================
echo   Flutter Path Configuration
echo ========================================
echo.
echo This will help you set FLUTTER_HOME so the app can find Flutter.
echo.
echo Where is your Flutter SDK installed?
echo Common locations:
echo   C:\src\flutter
echo   C:\flutter
echo   C:\development\flutter
echo   %USERPROFILE%\flutter
echo.
echo Please enter the FULL path to your Flutter SDK folder
echo (the folder that contains the 'bin' subfolder):
echo.

SET /P FLUTTER_PATH="Flutter SDK path: "

REM Remove quotes if user added them
SET FLUTTER_PATH=%FLUTTER_PATH:"=%

REM Validate the path
IF NOT EXIST "%FLUTTER_PATH%\bin\flutter.bat" (
    echo.
    echo [ERROR] Invalid path! Could not find flutter.bat at:
    echo   %FLUTTER_PATH%\bin\flutter.bat
    echo.
    echo Please make sure you entered the correct path to the Flutter SDK root folder.
    echo.
    pause
    exit /b 1
)

echo.
echo [OK] Found Flutter at: %FLUTTER_PATH%
echo.
echo Setting FLUTTER_HOME environment variable...

REM Set for current session
SET "FLUTTER_HOME=%FLUTTER_PATH%"

REM Set permanently for user
setx FLUTTER_HOME "%FLUTTER_PATH%" >nul 2>&1

IF ERRORLEVEL 1 (
    echo.
    echo [WARNING] Could not set FLUTTER_HOME permanently.
    echo You may need to run this script as Administrator.
    echo.
    echo For now, FLUTTER_HOME is set for this session only.
    echo.
) ELSE (
    echo [SUCCESS] FLUTTER_HOME has been set permanently!
    echo.
    echo Set to: %FLUTTER_PATH%
    echo.
    echo NOTE: You may need to restart Command Prompt or your IDE
    echo       for the changes to take effect everywhere.
    echo.
)

echo ========================================
echo   Configuration Complete
echo ========================================
echo.
echo You can now run start_app.bat to launch the app.
echo.
pause
