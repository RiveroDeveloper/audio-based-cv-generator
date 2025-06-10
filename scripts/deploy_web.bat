@echo off
echo ========================================
echo CV Scanner - Web Deployment Script
echo ========================================
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
if %errorlevel% neq 0 (
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
echo ⚠️  REMINDER: Update API keys in web/js/config.js
echo    if you haven't done so already!
echo.
pause 