@echo off
REM ==============================================================================
REM Specz.co - 1-Click Android Release APK Build Script
REM ==============================================================================
echo ========================================================
echo  Specz.co - Building Android Release APK
echo ========================================================

REM Step 1: Clean build cache
echo [1/3] Cleaning Flutter build cache...
call flutter clean

REM Step 2: Get packages
echo [2/3] Installing dependencies...
call flutter pub get

REM Step 3: Build APK
echo [3/3] Compiling Release APK...
call flutter build apk --release --no-tree-shake-icons --android-skip-build-dependency-validation

if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Flutter APK build failed! Check errors above.
    pause
    exit /b %ERRORLEVEL%
)

echo ========================================================
echo  BUILD SUCCESSFUL!
echo ========================================================
echo  Downloadable APK is located at:
echo  build\app\outputs\flutter-apk\app-release.apk
echo.
echo  To install directly to a connected Android phone:
echo    adb install -r build\app\outputs\flutter-apk\app-release.apk
echo ========================================================
pause
