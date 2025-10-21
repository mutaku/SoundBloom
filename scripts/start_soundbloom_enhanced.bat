@echo off
REM SoundBloom Enhanced Startup Script with PID Tracking
REM ===================================================
REM
REM This script starts SoundBloom on port 7000 and tracks PIDs for clean shutdown

setlocal enabledelayedexpansion

set SOUNDBLOOM_DIR=%~dp0
set PID_FILE=%SOUNDBLOOM_DIR%soundbloom.pid
set LOG_FILE=%SOUNDBLOOM_DIR%soundbloom.log
set PORT=7000

echo [%TIME%] Starting SoundBloom Enhanced System...
echo.

REM Clean up old PID file if it exists
if exist "%PID_FILE%" (
    echo [%TIME%] Cleaning up old PID file...
    del "%PID_FILE%" 2>nul
)

REM Check if port 7000 is available
echo [%TIME%] Checking if port %PORT% is available...
netstat -ano | findstr :%PORT% >nul 2>nul
if %errorlevel% equ 0 (
    echo ERROR: Port %PORT% is already in use!
    echo Please stop other applications using port %PORT% or choose a different port.
    echo.
    netstat -ano | findstr :%PORT%
    echo.
    pause
    exit /b 1
)

REM Check prerequisites
echo [%TIME%] Checking prerequisites...

where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Python not found in PATH
    echo Please install Python 3.11 or later
    echo Run: winget install Python.Python.3.11
    pause
    exit /b 1
)

where poetry >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Poetry not found in PATH
    echo Please install Poetry: pip install poetry
    pause
    exit /b 1
)

REM Change to SoundBloom directory
cd /d "%SOUNDBLOOM_DIR%"

REM Optional Neo4j startup (check if available)
where neo4j >nul 2>nul
if %errorlevel% equ 0 (
    echo [%TIME%] Checking Neo4j status...
    neo4j status >nul 2>nul
    if %errorlevel% neq 0 (
        echo [%TIME%] Starting Neo4j database...
        neo4j start
        if %errorlevel% equ 0 (
            echo [%TIME%] Neo4j started successfully
            timeout /t 5 /nobreak >nul
        ) else (
            echo WARNING: Failed to start Neo4j - continuing without database
        )
    ) else (
        echo [%TIME%] Neo4j is already running
    )
) else (
    echo [%TIME%] Neo4j not found - running in demo mode
)

echo.
echo [%TIME%] Starting SoundBloom server on port %PORT%...
echo [%TIME%] Access SoundBloom at: http://localhost:%PORT%
echo [%TIME%] Logs are being written to: %LOG_FILE%
echo [%TIME%] PID tracking file: %PID_FILE%
echo.
echo Press Ctrl+C to stop the server (or use stop_soundbloom_enhanced.bat)
echo.

REM Start SoundBloom and capture PID
start /b "" poetry run python run.py > "%LOG_FILE%" 2>&1

REM Get the PID of the started process
timeout /t 2 /nobreak >nul

REM Find Python process running SoundBloom
for /f "tokens=2" %%i in ('tasklist /fi "imagename eq python.exe" /fo csv ^| findstr /c:"python.exe"') do (
    set "FOUND_PID=%%~i"
    REM Verify this is our SoundBloom process by checking if it's using port 7000
    netstat -ano | findstr :%PORT% | findstr !FOUND_PID! >nul 2>nul
    if !errorlevel! equ 0 (
        echo [%TIME%] SoundBloom started successfully with PID: !FOUND_PID!
        echo !FOUND_PID! > "%PID_FILE%"
        echo %PORT% >> "%PID_FILE%"
        echo %DATE% %TIME% >> "%PID_FILE%"
        goto :found_pid
    )
)

echo WARNING: Could not determine SoundBloom PID
echo The server may have failed to start. Check %LOG_FILE% for details.

:found_pid
echo [%TIME%] SoundBloom is now running. Use stop_soundbloom_enhanced.bat to stop.
echo [%TIME%] Monitor logs with: Get-Content "%LOG_FILE%" -Wait
echo.

REM Keep the console open to show it's running
pause

echo.
echo [%TIME%] SoundBloom startup script finished.
