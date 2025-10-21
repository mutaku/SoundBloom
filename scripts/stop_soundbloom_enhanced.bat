@echo off
REM SoundBloom Enhanced Shutdown Script with PID Tracking
REM ====================================================
REM
REM This script safely stops SoundBloom using stored PID information

setlocal enabledelayedexpansion

set SOUNDBLOOM_DIR=%~dp0
set PID_FILE=%SOUNDBLOOM_DIR%soundbloom.pid

echo [%TIME%] Stopping SoundBloom Enhanced System...
echo.

REM Check if PID file exists
if not exist "%PID_FILE%" (
    echo WARNING: No PID file found at %PID_FILE%
    echo Attempting to find and stop SoundBloom processes manually...
    goto :manual_cleanup
)

REM Read PID from file
set /p SOUNDBLOOM_PID=< "%PID_FILE%"

if "%SOUNDBLOOM_PID%"=="" (
    echo ERROR: PID file is empty
    goto :manual_cleanup
)

echo [%TIME%] Found SoundBloom PID: %SOUNDBLOOM_PID%

REM Check if process is still running
tasklist /fi "pid eq %SOUNDBLOOM_PID%" | findstr %SOUNDBLOOM_PID% >nul 2>nul
if %errorlevel% neq 0 (
    echo [%TIME%] Process %SOUNDBLOOM_PID% is not running
    del "%PID_FILE%" 2>nul
    echo [%TIME%] Cleaned up stale PID file
    goto :check_port
)

REM Stop the specific SoundBloom process
echo [%TIME%] Stopping SoundBloom process %SOUNDBLOOM_PID%...
taskkill /pid %SOUNDBLOOM_PID% /f >nul 2>nul
if %errorlevel% equ 0 (
    echo [%TIME%] Successfully stopped SoundBloom process
) else (
    echo WARNING: Failed to stop process %SOUNDBLOOM_PID%
)

REM Clean up PID file
del "%PID_FILE%" 2>nul
echo [%TIME%] Cleaned up PID tracking file

goto :check_port

:manual_cleanup
echo [%TIME%] Performing manual cleanup of SoundBloom processes...

REM Look for Python processes that might be SoundBloom
echo [%TIME%] Searching for SoundBloom processes...

REM Check for processes using port 7000
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :7000') do (
    set "PORT_PID=%%a"
    if not "!PORT_PID!"=="" (
        echo [%TIME%] Found process using port 7000: !PORT_PID!
        tasklist /fi "pid eq !PORT_PID!" | findstr python >nul 2>nul
        if !errorlevel! equ 0 (
            echo [%TIME%] Stopping Python process !PORT_PID! using port 7000...
            taskkill /pid !PORT_PID! /f >nul 2>nul
            if !errorlevel! equ 0 (
                echo [%TIME%] Successfully stopped process !PORT_PID!
            )
        )
    )
)

:check_port
REM Verify port 7000 is free
echo [%TIME%] Checking if port 7000 is now free...
netstat -ano | findstr :7000 >nul 2>nul
if %errorlevel% neq 0 (
    echo [%TIME%] ✓ Port 7000 is now free
) else (
    echo WARNING: Port 7000 is still in use:
    netstat -ano | findstr :7000
)

REM Optional: Ask about Neo4j
where neo4j >nul 2>nul
if %errorlevel% equ 0 (
    echo.
    set /p STOP_NEO4J="Stop Neo4j as well? (y/N): "
    if /i "!STOP_NEO4J!"=="y" (
        echo [%TIME%] Stopping Neo4j...
        neo4j stop
        if %errorlevel% equ 0 (
            echo [%TIME%] Neo4j stopped successfully
        ) else (
            echo WARNING: Failed to stop Neo4j
        )
    )
)

echo.
echo [%TIME%] SoundBloom shutdown complete.
pause
