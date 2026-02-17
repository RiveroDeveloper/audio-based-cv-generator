@echo off
echo ========================================
echo CV Scanner - Web Deployment Script
echo ========================================
echo.

echo 📝 Generating config.js from .env...
dart run scripts/generate_config.dart
if %errorlevel% neq 0 (
    echo ❌ Error generating config!
    pause
    exit /b 1
)
echo.
echo 🔧 Building Flutter Web App...
flutter build web --release
if %errorlevel% neq 0 (
    echo ❌ Error building web app!
    pause
    exit /b 1
)
echo ✅ Web build completed!
echo.

echo 🚀 Deploying to Firebase Hosting...
firebase deploy
set DEPLOY_RESULT=%errorlevel%
if %DEPLOY_RESULT% equ 0 (
    echo 🗑️  Removing config.js from source...
    del /q web\js\config.js 2>nul
)
if %DEPLOY_RESULT% neq 0 (
    echo ❌ Error deploying to Firebase!
    pause
    exit /b 1
)
echo.

echo ========================================
echo ✅ Deployment completed successfully!
echo ========================================
echo.
echo 🌐 Your app is live at:
echo https://scanner-6c414.web.app
echo.
echo 📊 Firebase Console:
echo https://console.firebase.google.com/project/scanner-6c414/overview
echo.
echo ℹ️  Config is generated from .env at build time
echo.
pause 