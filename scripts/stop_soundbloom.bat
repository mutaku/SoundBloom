@echo off
REM SoundBloom Shutdown Script for Windows
REM =====================================
REM
REM This script safely stops the Reflex server and Neo4j database

echo Stopping SoundBloom System...
echo.

REM Stop any running Reflex processes
echo Looking for Reflex processes...
for /f "tokens=1" %%i in ('tasklist /fi "imagename eq python.exe" /fo csv ^| findstr reflex') do (
    echo Stopping Reflex process %%i...
    taskkill /pid %%i /f >nul 2>nul
)

REM Stop any running development servers on port 7000
echo Checking for processes on port 7000...
for /f "tokens=5" %%a in ('netstat -ano ^| findstr :7000') do (
    echo Stopping process on port 7000...
    taskkill /pid %%a /f >nul 2>nul
)

REM Stop Neo4j if it's running
echo Checking Neo4j status...
neo4j status >nul 2>nul
if %errorlevel% equ 0 (
    echo Stopping Neo4j database...
    neo4j stop
    if %errorlevel% equ 0 (
        echo Neo4j stopped successfully
    ) else (
        echo Warning: Failed to stop Neo4j gracefully
    )
) else (
    echo Neo4j was not running
)

echo.
echo SoundBloom system shutdown complete.
pause
