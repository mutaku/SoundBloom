@echo off
REM SoundBloom Startup Script for Windows
REM ====================================
REM
REM This script starts Neo4j and the Reflex server for SoundBloom
REM Checks for dependencies and provides helpful error messages

echo Starting SoundBloom System...
echo.

REM Check if Neo4j is installed
where neo4j >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Neo4j not found in PATH
    echo Please install Neo4j Desktop or Neo4j Community Edition
    echo Download from: https://neo4j.com/download/
    echo.
    pause
    exit /b 1
)

REM Check if Python is available
where python >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Python not found in PATH
    echo Please install Python 3.11 or later
    echo Run: winget install Python.Python.3.11
    echo.
    pause
    exit /b 1
)

REM Check if Poetry is available
where poetry >nul 2>nul
if %errorlevel% neq 0 (
    echo ERROR: Poetry not found in PATH
    echo Please install Poetry
    echo Run: pip install poetry
    echo.
    pause
    exit /b 1
)

REM Change to SoundBloom directory
cd /d "%~dp0"

echo Checking Neo4j status...
neo4j status
if %errorlevel% neq 0 (
    echo Starting Neo4j database...
    neo4j start
    if %errorlevel% neq 0 (
        echo ERROR: Failed to start Neo4j
        echo Please check Neo4j configuration and try again
        echo.
        pause
        exit /b 1
    )
    echo Neo4j started successfully
) else (
    echo Neo4j is already running
)

echo.
echo Waiting for Neo4j to be ready...
timeout /t 5 /nobreak >nul

REM Test Neo4j connection
echo Testing Neo4j connection...
python -c "
from neo4j import GraphDatabase
try:
    driver = GraphDatabase.driver('bolt://localhost:7687', auth=('neo4j', 'soundbloom'))
    driver.verify_connectivity()
    driver.close()
    print('Neo4j connection successful')
except Exception as e:
    print(f'Neo4j connection failed: {e}')
    exit(1)
"
if %errorlevel% neq 0 (
    echo ERROR: Cannot connect to Neo4j
    echo Please check Neo4j is running and credentials are correct
    echo Default credentials: neo4j/soundbloom
    echo.
    pause
    exit /b 1
)

echo.
echo Starting Reflex development server...
echo You can access SoundBloom at: http://localhost:7000
echo Press Ctrl+C to stop the server
echo.

REM Start Reflex server
poetry run reflex run --host 0.0.0.0 --port 7000

echo.
echo SoundBloom server stopped.
pause
