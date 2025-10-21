# SoundBloom Clean Stop Script
# ============================
# Clean shutdown with improved PID tracking and port management

param(
    [switch]$Force = $false,
    [switch]$Verbose = $false,
    [switch]$StopNeo4j = $false
)

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
            Add-Content -Path $LogFile -Value "[SUCCESS] $logEntry" -ErrorAction SilentlyContinue
        }
        "Error"   {
            Write-Host "[$timestamp] ✗ $Message" -ForegroundColor Red
            Add-Content -Path $LogFile -Value "[ERROR] $logEntry" -ErrorAction SilentlyContinue
        }
        "Warning" {
            Write-Host "[$timestamp] ⚠ $Message" -ForegroundColor Yellow
            Add-Content -Path $LogFile -Value "[WARNING] $logEntry" -ErrorAction SilentlyContinue
        }
        default   {
            Write-Host "[$timestamp] ℹ $Message" -ForegroundColor Cyan
            Add-Content -Path $LogFile -Value "[INFO] $logEntry" -ErrorAction SilentlyContinue
        }
    }
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
        Write-Status "Error checking port $PortNumber : $($_.Exception.Message)" -Type Warning
    }
    return $null
}

function Stop-ProcessSafely {
    param(
        [System.Diagnostics.Process]$Process,
        [string]$Description,
        [int]$GracefulTimeoutSeconds = 5
    )

    if (-not $Process) { return $false }

    try {
        Write-Status "Stopping $Description (PID: $($Process.Id))..."

        if (-not $Force) {
            # Try graceful shutdown first
            if ($Process.CloseMainWindow()) {
                Write-Status "Sent close signal to $Description"

                # Wait for graceful exit
                if ($Process.WaitForExit($GracefulTimeoutSeconds * 1000)) {
                    Write-Status "$Description stopped gracefully" -Type Success
                    return $true
                }
                else {
                    Write-Status "Graceful shutdown timed out for $Description" -Type Warning
                }
            }
        }

        # Force kill if graceful failed or Force flag is set
        if (-not $Process.HasExited) {
            $Process.Kill()
            $Process.WaitForExit(3000)
            Write-Status "$Description force stopped" -Type Success
        }

        return $true
    }
    catch {
        Write-Status "Failed to stop $Description : $($_.Exception.Message)" -Type Error
        return $false
    }
}

# Main shutdown logic
try {
    Write-Host ""
    Write-Status "🛑 Stopping SoundBloom Clean System..." -Type Warning
    Write-Host "=========================================" -ForegroundColor Red
    Write-Host ""

    $processFound = $false

    # Method 1: Stop using PID file (preferred method)
    if (Test-Path $PidFile) {
        Write-Status "Found PID file - attempting tracked shutdown..." -Type Info

        try {
            $pidData = Get-Content $PidFile
            $storedPid = $pidData[0]
            $storedPort = if ($pidData.Length -gt 1) { $pidData[1] } else { "Unknown" }
            $startTime = if ($pidData.Length -gt 2) { $pidData[2] } else { "Unknown" }

            Write-Status "Stored Info - PID: $storedPid, Port: $storedPort, Started: $startTime" -Type Info

            if ($storedPid -ne "STARTING") {
                $trackedProcess = Get-Process -Id $storedPid -ErrorAction SilentlyContinue
                if ($trackedProcess) {
                    $success = Stop-ProcessSafely -Process $trackedProcess -Description "SoundBloom (tracked)"
                    if ($success) { $processFound = $true }
                }
                else {
                    Write-Status "Tracked process (PID: $storedPid) not found - may have already stopped" -Type Warning
                }
            }
            else {
                Write-Status "Process was still starting when shutdown requested" -Type Warning
            }
        }
        catch {
            Write-Status "Error reading PID file: $($_.Exception.Message)" -Type Error
        }

        # Always clean up PID file
        Remove-Item $PidFile -Force -ErrorAction SilentlyContinue
        Write-Status "PID tracking file cleaned up" -Type Info
    }
    else {
        Write-Status "No PID file found - checking for running processes..." -Type Info
    }

    # Method 2: Check SoundBloom's designated port (7000)
    $soundbloomProcess = Get-ProcessOnPort -PortNumber 7000
    if ($soundbloomProcess) {
        if ($soundbloomProcess.ProcessName -eq "python") {
            Write-Status "Found SoundBloom process on port 7000" -Type Warning

            if ($Force -or (Read-Host "Stop SoundBloom process on port 7000? (Y/n)") -ne "n") {
                $success = Stop-ProcessSafely -Process $soundbloomProcess -Description "SoundBloom on port 7000"
                if ($success) { $processFound = $true }
            }
        }
        else {
            Write-Status "Non-Python process found on port 7000: $($soundbloomProcess.ProcessName)" -Type Warning
        }
    }

    # Method 3: Search for any Python Reflex processes
    try {
        $allPythonProcesses = Get-Process -Name "python" -ErrorAction SilentlyContinue
        $reflexProcesses = @()

        foreach ($proc in $allPythonProcesses) {
            try {
                # Check if it's a Reflex process (this is a best-effort check)
                $commandLine = $proc.CommandLine
                if ($commandLine -and ($commandLine -like "*reflex*" -or $commandLine -like "*soundbloom*")) {
                    $reflexProcesses += $proc
                }
            }
            catch {
                # CommandLine access might fail, skip this process
            }
        }

        if ($reflexProcesses.Count -gt 0) {
            Write-Status "Found $($reflexProcesses.Count) potential Reflex processes" -Type Info

            foreach ($proc in $reflexProcesses) {
                Write-Status "Potential SoundBloom process found (PID: $($proc.Id))" -Type Warning

                if ($Force -or (Read-Host "Stop this process? (Y/n)") -ne "n") {
                    $success = Stop-ProcessSafely -Process $proc -Description "Reflex process"
                    if ($success) { $processFound = $true }
                }
            }
        }
    }
    catch {
        Write-Status "Could not search for Reflex processes: $($_.Exception.Message)" -Type Warning
    }

    # Optional: Stop Neo4j if requested
    if ($StopNeo4j) {
        Write-Status "Stopping Neo4j database..." -Type Info
        try {
            if (Get-Command "neo4j" -ErrorAction SilentlyContinue) {
                & neo4j stop | Out-Null
                if ($LASTEXITCODE -eq 0) {
                    Write-Status "Neo4j stopped successfully" -Type Success
                }
                else {
                    Write-Status "Neo4j may not have been running" -Type Warning
                }
            }
            else {
                Write-Status "Neo4j command not found" -Type Warning
            }
        }
        catch {
            Write-Status "Error stopping Neo4j: $($_.Exception.Message)" -Type Error
        }
    }

    # Summary
    Write-Host ""
    if ($processFound) {
        Write-Status "🌸 SoundBloom shutdown completed successfully" -Type Success
    }
    else {
        Write-Status "🌸 No active SoundBloom processes found" -Type Info
    }

    Write-Status "All cleanup operations completed" -Type Success

} catch {
    Write-Status "Error during shutdown: $($_.Exception.Message)" -Type Error
    Add-Content -Path $LogFile -Value "[FATAL] Shutdown error: $($_.Exception.Message)" -ErrorAction SilentlyContinue
    exit 1
}

Write-Host ""
