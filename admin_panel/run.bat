@echo off
echo Starting Backend Server...
start "VisionFurnish Backend" cmd /c "cd /d C:\Users\Bhavesh\Desktop\vf && node server.js"
timeout /t 2 /nobreak >nul

echo Cleaning build directory...
if exist "build" rmdir /s /q "build" 2>nul

echo Starting Flutter on Chrome...
flutter run -d chrome
