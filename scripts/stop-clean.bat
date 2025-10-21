@echo off
REM SoundBloom Clean Stop (Batch Wrapper)
REM ====================================
REM Simple batch file to run the clean PowerShell stop script

echo.
echo 🛑 SoundBloom Clean Stop
echo ======================
echo.

REM Change to script directory
cd /d "%~dp0"

REM Run the clean PowerShell stop script
echo 🔧 Stopping SoundBloom with clean PowerShell script...
echo.

powershell -ExecutionPolicy Bypass -File "Stop-SoundBloom-Clean.ps1" %*

echo.
echo 🌸 SoundBloom Clean Stop completed
echo.
pause
