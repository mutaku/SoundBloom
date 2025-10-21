# SoundBloom Enhanced Startup & PID Management

## 🎯 **Problem Solved**
SoundBloom now runs on **port 7000** (avoiding conflicts with your existing apps on 3000/8000/8001) and includes **intelligent PID tracking** for clean startup/shutdown without affecting other applications.

## 🚀 **Available Startup Methods**

### **1. Enhanced PowerShell (Recommended)**
```powershell
# Standard startup with PID tracking
.\Start-SoundBloom-Enhanced.ps1

# Background mode (detached process)
.\Start-SoundBloom-Enhanced.ps1 -Background

# Development mode with verbose logging
.\Start-SoundBloom-Enhanced.ps1 -DevMode -Verbose
```

**Features:**
- ✅ **Port conflict detection** - Automatically handles port 7000 conflicts
- ✅ **PID file tracking** - Stores process ID in `soundbloom.pid`
- ✅ **Smart process isolation** - Only kills SoundBloom, not other apps
- ✅ **Comprehensive logging** - Detailed logs in `soundbloom.log`
- ✅ **Background mode** - Run detached from terminal

### **2. Enhanced Batch Scripts**
```batch
# Simple startup with PID tracking
start_soundbloom_enhanced.bat

# Clean shutdown using stored PID
stop_soundbloom_enhanced.bat
```

**Features:**
- ✅ **Cross-process PID tracking** - Remembers exact process to kill
- ✅ **Port verification** - Ensures port 7000 is free after shutdown
- ✅ **Fallback cleanup** - Manual process detection if PID file missing

### **3. Legacy Scripts (Still Available)**
```powershell
# Simple startup (now uses port 7000)
.\Start-SoundBloom.ps1 -Port 7000

# Batch file startup
start_soundbloom.bat
```

## 🎮 **How PID Tracking Works**

### **Startup Process:**
1. **Check port availability** - Scans port 7000 for conflicts
2. **Smart conflict resolution** - Only stops Python processes (likely SoundBloom)
3. **Start SoundBloom** - Launches on port 7000
4. **Capture PID** - Stores process ID in `soundbloom.pid` file
5. **Log session info** - Records startup time, port, host

### **PID File Format:**
```
12345          <- Process ID
7000          <- Port number
2025-10-20 15:30:15  <- Start timestamp
localhost     <- Host
job           <- Process type (process/job)
```

### **Shutdown Process:**
1. **Read PID file** - Gets exact process ID to stop
2. **Graceful shutdown** - Tries clean process termination first
3. **Force if needed** - Uses kill only if graceful fails
4. **Verify cleanup** - Ensures port 7000 is free
5. **Clean tracking files** - Removes PID file

## 🛡️ **Safety Features**

### **Process Isolation:**
- **Only targets SoundBloom processes** - Won't affect your other apps
- **Port-specific detection** - Only processes using port 7000
- **Python process filtering** - Identifies SoundBloom vs other Python apps
- **Confirmation prompts** - Asks before stopping non-SoundBloom processes

### **Conflict Resolution:**
```powershell
# If port 7000 is busy:
Found process on port 7000: MyOtherApp.exe (PID: 8888)
Non-Python process detected on port 7000
Please stop MyOtherApp or choose a different port
```

### **Automatic Recovery:**
- **Stale PID cleanup** - Removes old PID files from crashed processes
- **Port verification** - Double-checks port availability
- **Fallback detection** - Manual process search if PID tracking fails

## 📊 **Quick Usage Examples**

### **Start SoundBloom (Enhanced)**
```powershell
# Start normally (foreground)
.\Start-SoundBloom-Enhanced.ps1

# Start in background (continues after closing terminal)
.\Start-SoundBloom-Enhanced.ps1 -Background

# Check it's running
Get-Content .\soundbloom.pid
# Output: 12345, 7000, 2025-10-20...

# Visit http://localhost:7000
```

### **Stop SoundBloom (Clean)**
```powershell
# Stop using PID tracking
.\Stop-SoundBloom.ps1

# Force stop everything on port 7000
.\Stop-SoundBloom.ps1 -Force

# Stop and also shutdown Neo4j
.\Stop-SoundBloom.ps1 -StopNeo4j
```

### **Monitor & Debug**
```powershell
# Check what's running on port 7000
netstat -ano | findstr :7000

# View live logs
Get-Content .\soundbloom.log -Wait

# Check PID file contents
Get-Content .\soundbloom.pid
```

## 🔧 **Troubleshooting**

### **Port Already in Use:**
```powershell
# Enhanced script handles this automatically
.\Start-SoundBloom-Enhanced.ps1
# Output: "Detected Python process on port 7000 - stopping it..."
```

### **PID File Missing:**
```powershell
# Stop script detects and handles this
.\Stop-SoundBloom.ps1
# Output: "No PID file found - attempting manual cleanup..."
```

### **Process Won't Stop:**
```powershell
# Force stop any process on port 7000
.\Stop-SoundBloom.ps1 -Force
```

## 🎉 **Benefits**

### **For Development:**
- **No more port conflicts** with your existing apps (3000, 8000, 8001)
- **Clean process management** - Start/stop specific to SoundBloom
- **Background operation** - Continue working while SoundBloom runs
- **Detailed logging** - Debug startup issues easily

### **For Production:**
- **Reliable startup/shutdown** - No orphaned processes
- **Process isolation** - Won't interfere with other services
- **Automatic recovery** - Handles crashed processes cleanly
- **Windows service ready** - Can be adapted for service deployment

## 📝 **Quick Reference**

| Task | Enhanced Command | Legacy Command |
|------|------------------|----------------|
| **Start** | `.\Start-SoundBloom-Enhanced.ps1` | `.\Start-SoundBloom.ps1` |
| **Start (Background)** | `.\Start-SoundBloom-Enhanced.ps1 -Background` | N/A |
| **Stop** | `.\Stop-SoundBloom.ps1` | `.\stop_soundbloom.bat` |
| **Force Stop** | `.\Stop-SoundBloom.ps1 -Force` | Manual process kill |
| **Check Status** | `Get-Content .\soundbloom.pid` | `netstat -ano \| findstr :7000` |
| **View Logs** | `Get-Content .\soundbloom.log -Wait` | Terminal output |

**Default URL:** http://localhost:7000 🌸
