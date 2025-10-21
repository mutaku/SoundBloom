# SoundBloom PowerShell Startup Script
# ====================================
#
# Enhanced startup script with better error handling and status monitoring
# Requires PowerShell 5.0 or later

param(
    [switch]$DevMode = $false,
    [string]$HostName = "localhost",
    [int]$Port = 7000,
    [switch]$NoNeo4j = $false,
    [switch]$Verbose = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

function Write-Status {
    param([string]$Message, [string]$Type = "Info")

    $timestamp = Get-Date -Format "HH:mm:ss"
    switch ($Type) {
        "Success" { Write-Host "[$timestamp] ✓ $Message" -ForegroundColor Green }
        "Error"   { Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow }
        default   { Write-Host "[$timestamp] ℹ $Message" -ForegroundColor Cyan }
    }
}

function Test-Command {
    param([string]$CommandName)
    return (Get-Command $CommandName -ErrorAction SilentlyContinue) -ne $null
}

function Test-Port {
    param([int]$Port)
    try {
        $connection = New-Object System.Net.Sockets.TcpClient
        $connection.Connect("localhost", $Port)
        $connection.Close()
        return $true
    }
    catch {
        return $false
    }
}

function Wait-ForNeo4j {
    param([int]$TimeoutSeconds = 30)

    Write-Status "Waiting for Neo4j to be ready..."
    $timeout = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $timeout) {
        try {
            # Test Neo4j connection using Python
            $testResult = python -c @"
from neo4j import GraphDatabase
import sys
try:
    driver = GraphDatabase.driver('bolt://localhost:7687', auth=('neo4j', 'soundbloom'))
    driver.verify_connectivity()
    driver.close()
    sys.exit(0)
except:
    sys.exit(1)
"@
            if ($LASTEXITCODE -eq 0) {
                Write-Status "Neo4j is ready" -Type Success
                return $true
            }
        }
        catch {
            # Ignore connection errors during startup
        }

        Start-Sleep -Seconds 2
        Write-Host "." -NoNewline
    }

    Write-Host ""
    Write-Status "Timeout waiting for Neo4j" -Type Error
    return $false
}

try {
    Write-Host ""
    Write-Status "Starting SoundBloom System" -Type Success
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""

    # Check prerequisites
    Write-Status "Checking prerequisites..."

    if (-not (Test-Command "python")) {
        Write-Status "Python not found. Please install Python 3.11+" -Type Error
        Write-Status "Run: winget install Python.Python.3.11" -Type Warning
        exit 1
    }

    if (-not (Test-Command "poetry")) {
        Write-Status "Poetry not found. Please install Poetry" -Type Error
        Write-Status "Run: pip install poetry" -Type Warning
        exit 1
    }

    if (-not $NoNeo4j -and -not (Test-Command "neo4j")) {
        Write-Status "Neo4j not found. Please install Neo4j Desktop or Community Edition" -Type Error
        Write-Status "Download from: https://neo4j.com/download/" -Type Warning
        exit 1
    }

    # Change to project directory
    Set-Location $PSScriptRoot
    Write-Status "Working directory: $(Get-Location)"

    # Start Neo4j if requested
    if (-not $NoNeo4j) {
        Write-Status "Checking Neo4j status..."

        $neo4jStatus = & neo4j status 2>&1
        if ($LASTEXITCODE -ne 0) {
            Write-Status "Starting Neo4j database..."
            & neo4j start
            if ($LASTEXITCODE -ne 0) {
                Write-Status "Failed to start Neo4j" -Type Error
                exit 1
            }
        } else {
            Write-Status "Neo4j is already running"
        }

        # Wait for Neo4j to be ready
        if (-not (Wait-ForNeo4j)) {
            Write-Status "Neo4j failed to start properly" -Type Error
            exit 1
        }
    }

    # Check if port is available
    if (Test-Port $Port) {
        Write-Status "Port $Port is already in use" -Type Warning
        $response = Read-Host "Continue anyway? (y/N)"
        if ($response -ne "y" -and $response -ne "Y") {
            Write-Status "Startup cancelled by user"
            exit 0
        }
    }

    # Start Reflex server
    Write-Host ""
    Write-Status "Starting Reflex development server..." -Type Success
    Write-Status "Access SoundBloom at: http://${HostName}:${Port}" -Type Success
    Write-Status "Press Ctrl+C to stop the server" -Type Warning
    Write-Host ""

    $reflexArgs = @("run")
    if ($DevMode) {
        $reflexArgs += "--dev"
    }
    $reflexArgs += @("--host", $HostName, "--port", $Port.ToString())

    if ($Verbose) {
        $reflexArgs += "--verbose"
    }

    # Start Reflex in Poetry environment
    & poetry $reflexArgs

} catch {
    Write-Status "Startup failed: $($_.Exception.Message)" -Type Error
    exit 1
} finally {
    Write-Host ""
    Write-Status "SoundBloom server stopped" -Type Warning
    if (-not $NoNeo4j) {
        $response = Read-Host "Stop Neo4j as well? (y/N)"
        if ($response -eq "y" -or $response -eq "Y") {
            Write-Status "Stopping Neo4j..."
            & neo4j stop
        }
    }
}
