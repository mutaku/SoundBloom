# SoundBloom Enhanced PowerShell Startup Script with PID Tracking
# ==============================================================
#
# Advanced startup script with PID tracking, port management, and process isolation
# Ensures SoundBloom runs on port 7000 without interfering with other apps

param(
    [switch]$DevMode = $false,
    [string]$Host = "localhost",
    [int]$Port = 7000,
    [switch]$NoNeo4j = $false,
    [switch]$Verbose = $false,
    [switch]$Background = $false
)

# Set error handling
$ErrorActionPreference = "Stop"

# Configuration
$ProjectRoot = $PSScriptRoot
$PidFile = Join-Path $ProjectRoot "soundbloom.pid"
$LogFile = Join-Path $ProjectRoot "soundbloom.log"

function Write-Status {
    param([string]$Message, [string]$Type = "Info")

    $timestamp = Get-Date -Format "HH:mm:ss"
    $logEntry = "[$timestamp] $Message"

    switch ($Type) {
        "Success" {
            Write-Host "[$timestamp] ✓ $Message" -ForegroundColor Green
            Add-Content -Path $LogFile -Value "[SUCCESS] $logEntry"
        }
        "Error"   {
            Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red
            Add-Content -Path $LogFile -Value "[ERROR] $logEntry"
        }
        "Warning" {
            Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow
            Add-Content -Path $LogFile -Value "[WARNING] $logEntry"
        }
        default   {
            Write-Host "[$timestamp] ℹ $Message" -ForegroundColor Cyan
            Add-Content -Path $LogFile -Value "[INFO] $logEntry"
        }
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

function Get-ProcessOnPort {
    param([int]$Port)

    try {
        $netstatOutput = netstat -ano | Select-String ":$Port "
        if ($netstatOutput) {
            $pidMatch = $netstatOutput | Select-String "(\d+)$" | Select-Object -First 1
            if ($pidMatch) {
                $pid = [int]($pidMatch.Matches[0].Groups[1].Value)
                return Get-Process -Id $pid -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        return $null
    }
    return $null
}

function Stop-SoundBloomProcess {
    param([string]$Reason = "Cleanup")

    Write-Status "Stopping SoundBloom process ($Reason)..." -Type Warning

    if (Test-Path $PidFile) {
        try {
            $pidData = Get-Content $PidFile
            $storedPid = [int]$pidData[0]

            $process = Get-Process -Id $storedPid -ErrorAction SilentlyContinue
            if ($process) {
                Write-Status "Stopping SoundBloom process (PID: $storedPid)..."
                $process.Kill()
                $process.WaitForExit(5000)
                Write-Status "Process stopped successfully" -Type Success
            }
        }
        catch {
            Write-Status "Could not stop process using PID file" -Type Warning
        }

        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
    }

    # Fallback: check port-based cleanup
    $processOnPort = Get-ProcessOnPort -Port $Port
    if ($processOnPort -and $processOnPort.ProcessName -eq "python") {
        Write-Status "Found Python process on port $Port (PID: $($processOnPort.Id))" -Type Warning
        try {
            $processOnPort.Kill()
            Write-Status "Stopped process on port $Port" -Type Success
        }
        catch {
            Write-Status "Failed to stop process on port $Port" -Type Error
        }
    }
}

function Wait-ForNeo4j {
    param([int]$TimeoutSeconds = 30)

    Write-Status "Waiting for Neo4j to be ready..."
    $timeout = (Get-Date).AddSeconds($TimeoutSeconds)

    while ((Get-Date) -lt $timeout) {
        try {
            $testResult = & python -c @"
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
    Write-Status "Timeout waiting for Neo4j" -Type Warning
    return $false
}

# Main startup logic
try {
    Write-Host ""
    Write-Status "🌸 Starting SoundBloom Enhanced System" -Type Success
    Write-Host "==========================================" -ForegroundColor Cyan
    Write-Host ""

    # Initialize log file
    "=== SoundBloom Startup Log $(Get-Date) ===" | Out-File -FilePath $LogFile -Encoding UTF8

    # Clean up any existing SoundBloom processes
    if (Test-Path $PidFile) {
        Write-Status "Found existing PID file - cleaning up..." -Type Warning
        Stop-SoundBloomProcess -Reason "Existing instance"
    }

    # Check if port is available
    if (Test-Port $Port) {
        Write-Status "Port $Port is currently in use" -Type Warning

        $processOnPort = Get-ProcessOnPort -Port $Port
        if ($processOnPort) {
            Write-Status "Process using port $Port: $($processOnPort.ProcessName) (PID: $($processOnPort.Id))" -Type Warning

            # Only auto-kill if it's a Python process (likely another SoundBloom instance)
            if ($processOnPort.ProcessName -eq "python") {
                Write-Status "Detected Python process on SoundBloom port - stopping it..." -Type Warning
                try {
                    $processOnPort.Kill()
                    Start-Sleep -Seconds 2
                }
                catch {
                    Write-Status "Failed to stop existing Python process" -Type Error
                    Write-Status "Please manually stop the process using port $Port" -Type Error
                    exit 1
                }
            }
            else {
                Write-Status "Non-Python process detected on port $Port" -Type Error
                Write-Status "Please stop the application using port $Port or choose a different port" -Type Error
                exit 1
            }
        }
    }

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

    # Change to project directory
    Set-Location $ProjectRoot
    Write-Status "Working directory: $(Get-Location)"

    # Handle Neo4j startup
    if (-not $NoNeo4j) {
        if (Test-Command "neo4j") {
            Write-Status "Checking Neo4j status..."

            $neo4jStatus = & neo4j status 2>&1
            if ($LASTEXITCODE -ne 0) {
                Write-Status "Starting Neo4j database..."
                & neo4j start
                if ($LASTEXITCODE -eq 0) {
                    if (-not (Wait-ForNeo4j)) {
                        Write-Status "Neo4j startup timeout - continuing anyway" -Type Warning
                    }
                } else {
                    Write-Status "Failed to start Neo4j - continuing without database" -Type Warning
                }
            } else {
                Write-Status "Neo4j is already running"
            }
        } else {
            Write-Status "Neo4j not found - running in demo mode" -Type Warning
        }
    }

    # Start SoundBloom server
    Write-Host ""
    Write-Status "🚀 Starting SoundBloom server on port $Port..." -Type Success
    Write-Status "📱 Access SoundBloom at: http://${Host}:${Port}" -Type Success
    Write-Status "📊 Logs: $LogFile" -Type Info
    Write-Status "🔍 PID tracking: $PidFile" -Type Info
    Write-Host ""

    # Build command arguments
    $args = @("run", "python", "run.py")

    # Start the process
    if ($Background) {
        # Start in background
        $processStartInfo = New-Object System.Diagnostics.ProcessStartInfo
        $processStartInfo.FileName = "poetry"
        $processStartInfo.Arguments = $args -join " "
        $processStartInfo.WorkingDirectory = $ProjectRoot
        $processStartInfo.UseShellExecute = $false
        $processStartInfo.CreateNoWindow = $true
        $processStartInfo.RedirectStandardOutput = $true
        $processStartInfo.RedirectStandardError = $true

        $process = [System.Diagnostics.Process]::Start($processStartInfo)

        # Save PID information
        $pidInfo = @(
            $process.Id
            $Port
            (Get-Date).ToString()
            $Host
        )
        $pidInfo | Out-File -FilePath $PidFile -Encoding UTF8

        Write-Status "SoundBloom started in background (PID: $($process.Id))" -Type Success
        Write-Status "Use Stop-SoundBloom.ps1 to stop the server" -Type Info

    } else {
        # Start in foreground
        Write-Status "Press Ctrl+C to stop the server" -Type Warning
        Write-Host ""

        # Start and capture PID
        $job = Start-Job -ScriptBlock {
            param($ProjectRoot, $args)
            Set-Location $ProjectRoot
            & poetry @args
        } -ArgumentList $ProjectRoot, $args

        # Save job information for cleanup
        $pidInfo = @(
            $job.Id
            $Port
            (Get-Date).ToString()
            $Host
            "job"
        )
        $pidInfo | Out-File -FilePath $PidFile -Encoding UTF8

        Write-Status "SoundBloom job started (Job ID: $($job.Id))" -Type Success

        # Wait for job and show output
        try {
            Wait-Job $job | Receive-Job
        }
        finally {
            Remove-Job $job -Force -ErrorAction SilentlyContinue
            Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        }
    }

} catch {
    Write-Status "Startup failed: $($_.Exception.Message)" -Type Error
    Add-Content -Path $LogFile -Value "[FATAL] Startup failed: $($_.Exception.Message)"
    exit 1
} finally {
    if (-not $Background) {
        Write-Host ""
        Write-Status "🌸 SoundBloom server stopped" -Type Warning

        if (-not $NoNeo4j -and (Test-Command "neo4j")) {
            $response = Read-Host "Stop Neo4j as well? (y/N)"
            if ($response -eq "y" -or $response -eq "Y") {
                Write-Status "Stopping Neo4j..."
                & neo4j stop | Out-Null
                Write-Status "Neo4j stopped" -Type Success
            }
        }
    }
}
