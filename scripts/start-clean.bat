@echo off
REM SoundBloom Clean Startup (Batch Wrapper)
REM =========================================
REM Simple batch file to run the clean PowerShell startup script

echo.
echo 🌸 SoundBloom Clean Startup
echo ==========================
echo.

REM Change to script directory
cd /d "%~dp0"

REM Check if PowerShell is available
powershell -Command "Write-Host 'PowerShell Available'" >nul 2>&1
if errorlevel 1 (
    echo ❌ PowerShell not found
    echo Please ensure PowerShell is installed and accessible
    pause
    exit /b 1
)

REM Run the clean PowerShell startup script
echo 🚀 Starting SoundBloom with clean PowerShell script...
echo.

powershell -ExecutionPolicy Bypass -File "Start-SoundBloom-Clean.ps1" %*

echo.
echo 🌸 SoundBloom Clean Startup completed
echo.
pause
