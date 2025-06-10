@echo off
echo ========================================
echo CV Scanner - Android Build Script
echo ========================================
echo.

echo Building Debug APK...
flutter build apk --debug
if %errorlevel% neq 0 (
    echo Error building debug APK!
    pause
    exit /b 1
)
echo ✅ Debug APK created: build\app\outputs\flutter-apk\app-debug.apk
echo.

echo Building Release APK...
flutter build apk --release
if %errorlevel% neq 0 (
    echo Error building release APK!
    pause
    exit /b 1
)
echo ✅ Release APK created: build\app\outputs\flutter-apk\app-release.apk
echo.

echo Building Android App Bundle (AAB for Play Store)...
flutter build appbundle --release
if %errorlevel% neq 0 (
    echo Error building AAB!
    pause
    exit /b 1
)
echo ✅ App Bundle created: build\app\outputs\bundle\release\app-release.aab
echo.

echo ========================================
echo ✅ All Android builds completed!
echo ========================================
echo.
echo Files created:
echo - Debug APK: build\app\outputs\flutter-apk\app-debug.apk
echo - Release APK: build\app\outputs\flutter-apk\app-release.apk  
echo - App Bundle: build\app\outputs\bundle\release\app-release.aab
echo.
echo The Release APK can be installed on any Android device.
echo The App Bundle (AAB) is for uploading to Google Play Store.
echo.
pause 