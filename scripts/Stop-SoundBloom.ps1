# SoundBloom Enhanced PowerShell Stop Script
# ==========================================
#
# Safely stops SoundBloom using PID tracking information

param(
    [switch]$Force = $false,
    [switch]$StopNeo4j = $false
)

$ProjectRoot = $PSScriptRoot
$PidFile = Join-Path $ProjectRoot "soundbloom.pid"
$LogFile = Join-Path $ProjectRoot "soundbloom.log"

function Write-Status {
    param([string]$Message, [string]$Type = "Info")

    $timestamp = Get-Date -Format "HH:mm:ss"

    switch ($Type) {
        "Success" { Write-Host "[$timestamp] ✓ $Message" -ForegroundColor Green }
        "Error"   { Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red }
        "Warning" { Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow }
        default   { Write-Host "[$timestamp] ℹ $Message" -ForegroundColor Cyan }
    }

    # Also log to file
    Add-Content -Path $LogFile -Value "[$timestamp] [$Type] $Message" -ErrorAction SilentlyContinue
}

function Get-ProcessOnPort {
    param([int]$PortNumber)

    try {
        $netstatOutput = netstat -ano | Select-String ":$PortNumber "
        if ($netstatOutput) {
            $pidMatch = $netstatOutput | Select-String "(\d+)$" | Select-Object -First 1
            if ($pidMatch) {
                $processId = [int]($pidMatch.Matches[0].Groups[1].Value)
                return Get-Process -Id $processId -ErrorAction SilentlyContinue
            }
        }
    }
    catch {
        return $null
    }
    return $null
}

try {
    Write-Host ""
    Write-Status "🛑 Stopping SoundBloom Enhanced System" -Type Warning
    Write-Host "=========================================" -ForegroundColor Yellow
    Write-Host ""

    $stopped = $false

    # Method 1: Use PID file if it exists
    if (Test-Path $PidFile) {
        Write-Status "Found PID tracking file..."

        try {
            $pidData = Get-Content $PidFile
            if ($pidData.Count -ge 2) {
                $storedPid = $pidData[0]
                $storedPort = $pidData[1]
                $startTime = if ($pidData.Count -gt 2) { $pidData[2] } else { "Unknown" }
                $processType = if ($pidData.Count -gt 4) { $pidData[4] } else { "process" }

                Write-Status "Stored PID: $storedPid, Port: $storedPort, Started: $startTime"

                if ($processType -eq "job") {
                    # It's a PowerShell job
                    $job = Get-Job -Id $storedPid -ErrorAction SilentlyContinue
                    if ($job) {
                        Write-Status "Stopping PowerShell job (ID: $storedPid)..."
                        Stop-Job $job -PassThru | Remove-Job -Force
                        Write-Status "Job stopped successfully" -Type Success
                        $stopped = $true
                    }
                    else {
                        Write-Status "Job $storedPid not found (may have already stopped)" -Type Warning
                    }
                }
                else {
                    # It's a regular process
                    $process = Get-Process -Id $storedPid -ErrorAction SilentlyContinue
                    if ($process) {
                        Write-Status "Stopping SoundBloom process (PID: $storedPid)..."

                        if ($Force) {
                            $process.Kill()
                        } else {
                            $process.CloseMainWindow()
                            if (-not $process.WaitForExit(5000)) {
                                Write-Status "Process didn't stop gracefully, forcing..." -Type Warning
                                $process.Kill()
                            }
                        }

                        Write-Status "Process stopped successfully" -Type Success
                        $stopped = $true
                    }
                    else {
                        Write-Status "Process $storedPid not found (may have already stopped)" -Type Warning
                    }
                }
            }
        }
        catch {
            Write-Status "Error reading PID file: $($_.Exception.Message)" -Type Error
        }

        # Clean up PID file
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        Write-Status "Cleaned up PID tracking file"
    }
    else {
        Write-Status "No PID file found - attempting manual cleanup..."
    }

    # Method 2: Check port 7000 for any remaining processes
    Write-Status "Checking port 7000 for active processes..."
    $processOnPort = Get-ProcessOnPort -PortNumber 7000

    if ($processOnPort) {
        Write-Status "Found process on port 7000: $($processOnPort.ProcessName) (PID: $($processOnPort.Id))" -Type Warning

        if ($processOnPort.ProcessName -eq "python" -or $Force) {
            Write-Status "Stopping process on port 7000..."
            try {
                if ($Force) {
                    $processOnPort.Kill()
                } else {
                    $processOnPort.CloseMainWindow()
                    if (-not $processOnPort.WaitForExit(3000)) {
                        $processOnPort.Kill()
                    }
                }
                Write-Status "Port 7000 process stopped" -Type Success
                $stopped = $true
            }
            catch {
                Write-Status "Failed to stop process on port 7000: $($_.Exception.Message)" -Type Error
            }
        }
        else {
            Write-Status "Process on port 7000 is not Python - skipping (use -Force to stop anyway)" -Type Warning
        }
    }
    else {
        Write-Status "No process found on port 7000" -Type Success
    }

    # Method 3: Look for any remaining SoundBloom processes
    Write-Status "Searching for other SoundBloom processes..."
    $soundBloomProcesses = Get-Process | Where-Object {
        $_.ProcessName -eq "python" -and
        $_.CommandLine -like "*soundbloom*"
    } -ErrorAction SilentlyContinue

    if ($soundBloomProcesses) {
        Write-Status "Found $($soundBloomProcesses.Count) SoundBloom-related process(es)"
        foreach ($proc in $soundBloomProcesses) {
            Write-Status "Stopping SoundBloom process PID: $($proc.Id)"
            try {
                $proc.Kill()
                Write-Status "Process $($proc.Id) stopped" -Type Success
                $stopped = $true
            }
            catch {
                Write-Status "Failed to stop process $($proc.Id)" -Type Error
            }
        }
    }

    # Final port verification
    Start-Sleep -Seconds 2
    $finalCheck = Get-ProcessOnPort -PortNumber 7000
    if ($null -eq $finalCheck) {
        Write-Status "✓ Port 7000 is now free" -Type Success
    }
    else {
        Write-Status "⚠ Port 7000 is still in use by: $($finalCheck.ProcessName) (PID: $($finalCheck.Id))" -Type Warning
    }

    # Handle Neo4j if requested
    if ($StopNeo4j -or (Get-Command "neo4j" -ErrorAction SilentlyContinue)) {
        if (-not $StopNeo4j) {
            $response = Read-Host "Stop Neo4j database as well? (y/N)"
            $StopNeo4j = ($response -eq "y" -or $response -eq "Y")
        }

        if ($StopNeo4j) {
            Write-Status "Stopping Neo4j database..."
            try {
                & neo4j stop | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "Neo4j stopped successfully" -Type Success
                } else {
                    Write-Status "Neo4j may not have been running" -Type Warning
                }
            }
            catch {
                Write-Status "Error stopping Neo4j: $($_.Exception.Message)" -Type Error
            }
        }
    }

    if ($stopped) {
        Write-Status "🌸 SoundBloom shutdown complete" -Type Success
    }
    else {
        Write-Status "No active SoundBloom processes found" -Type Warning
    }

} catch {
    Write-Status "Shutdown script error: $($_.Exception.Message)" -Type Error
    exit 1
}

Write-Host ""
