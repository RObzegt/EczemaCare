@echo off
REM ===============================================
REM   Flutter Installation Test
REM ===============================================
REM Quick test to verify Flutter is accessible
REM ===============================================

echo.
echo ========================================
echo   Testing Flutter Installation
echo ========================================
echo.

SET "FLUTTER_PATH=C:\Down\orions2\flutter"

echo [Test 1] Checking if Flutter folder exists...
IF NOT EXIST "%FLUTTER_PATH%" (
    echo [FAIL] Flutter folder not found at: %FLUTTER_PATH%
    echo.
    pause
    exit /b 1
)
echo [PASS] Flutter folder exists
echo.

echo [Test 2] Checking if flutter.bat exists...
IF NOT EXIST "%FLUTTER_PATH%\bin\flutter.bat" (
    echo [FAIL] flutter.bat not found at: %FLUTTER_PATH%\bin\flutter.bat
    echo.
    pause
    exit /b 1
)
echo [PASS] flutter.bat found
echo.

echo [Test 3] Running Flutter version check...
echo Command: "%FLUTTER_PATH%\bin\flutter.bat" --version
echo.
"%FLUTTER_PATH%\bin\flutter.bat" --version
IF ERRORLEVEL 1 (
    echo.
    echo [FAIL] Flutter command failed to execute
    echo.
    pause
    exit /b 1
)
echo.
echo [PASS] Flutter is working correctly!
echo.

echo [Test 4] Checking Flutter doctor...
echo This shows the status of your Flutter environment:
echo.
"%FLUTTER_PATH%\bin\flutter.bat" doctor
echo.

echo ========================================
echo   All Tests Passed!
echo ========================================
echo.
echo Flutter is installed correctly at:
echo   %FLUTTER_PATH%
echo.
echo You can now run start_app.bat to launch the app.
echo.
pause
