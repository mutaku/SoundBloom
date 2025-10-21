# SoundBloom Quick Start & Testing Guide

## 🚀 Quick Start (Windows)

### Method 1: Simple Double-Click Start
1. **Double-click `start_soundbloom.bat`** in the project folder
2. Wait for the console to show "You can access SoundBloom at: http://localhost:7000"
3. Open your browser and go to **http://localhost:7000**
4. To stop: Press `Ctrl+C` in the console, then double-click `stop_soundbloom.bat`

### Method 2: Enhanced PowerShell Start (Recommended)
1. **Right-click `Start-SoundBloom-Enhanced.ps1`** → "Run with PowerShell"
2. Or open PowerShell in the project folder and run:
   ```powershell
   .\Start-SoundBloom-Enhanced.ps1
   ```
3. For development mode with auto-reload:
   ```powershell
   .\Start-SoundBloom-Enhanced.ps1 -DevMode -Verbose
   ```
4. To run in background (detached):
   ```powershell
   .\Start-SoundBloom-Enhanced.ps1 -Background
   ```

### Method 3: Legacy PowerShell Start
1. **Right-click `Start-SoundBloom.ps1`** → "Run with PowerShell"
2. For custom port: `.\Start-SoundBloom.ps1 -Port 7001`

## 🛠️ System Requirements Check

### Prerequisites
- **Python 3.11+** (check: `python --version`)
- **Poetry** (check: `poetry --version`)
- **Neo4j Desktop/Community** (check: `neo4j status`)

### Install Missing Components
```powershell
# Install Python
winget install Python.Python.3.11

# Install Poetry
pip install poetry

# Install Neo4j Desktop (recommended)
# Download from: https://neo4j.com/download/neo4j-desktop/
```

## 🧪 Testing Your Installation

### 1. Basic System Test
```powershell
# Test Python environment
python -c "import sys; print(f'Python {sys.version}')"

# Test Poetry environment
poetry env info

# Test Neo4j connection
poetry run python -c "
from neo4j import GraphDatabase
driver = GraphDatabase.driver('bolt://localhost:7687', auth=('neo4j', 'soundbloom'))
driver.verify_connectivity()
print('✅ Neo4j connection successful')
"
```

### 2. Component Testing

#### Test Database Models
```powershell
poetry run python -c "
from soundbloom.database.models import Recording, IdeaConcept
from datetime import datetime
print('✅ Database models import successfully')
"
```

#### Test USB Device Detection
```powershell
poetry run python -c "
from soundbloom.import_manager.usb_import import USBDeviceManager
manager = USBDeviceManager()
devices = manager.scan_removable_drives()
print(f'✅ Found {len(devices)} USB devices')
"
```

#### Test Audio Processing
```powershell
poetry run python -c "
import librosa
print('✅ Librosa (audio processing) available')
import openai
print('✅ OpenAI client available')
"
```

### 3. Web Interface Test
1. Start SoundBloom: `.\Start-SoundBloom-Enhanced.ps1`
2. Open **http://localhost:7000**
3. Check these pages work:
   - **Home** - Should show SoundBloom dashboard
   - **Import** - Should detect USB devices
   - **Recordings** - Should show recordings list (empty initially)
   - **Concept Board** - Should show concept visualization

### 4. Enhanced PID Tracking Test
```powershell
# Start in background
.\Start-SoundBloom-Enhanced.ps1 -Background

# Check PID file created
Get-Content .\soundbloom.pid

# Stop using PID tracking
.\Stop-SoundBloom.ps1

# Verify port is free
netstat -ano | findstr :7000
```

## 🔧 Troubleshooting

### Common Issues & Solutions

#### Neo4j Won't Start
```powershell
# Check if Neo4j service is running
neo4j status

# If not installed via Neo4j Desktop, start manually:
neo4j start

# Check Neo4j logs
# Windows: %NEO4J_HOME%\logs\neo4j.log
```

#### Port 7000 Already in Use
```powershell
# Find what's using port 7000
netstat -ano | findstr :7000

# Kill the process (replace PID) - ONLY if it's not another important app
taskkill /pid <PID> /f

# Or start on different port
.\Start-SoundBloom.ps1 -Port 7001

# Enhanced script automatically handles port conflicts
.\Start-SoundBloom-Enhanced.ps1
```

#### Poetry Environment Issues
```powershell
# Recreate virtual environment
poetry env remove python
poetry install

# Activate environment manually
poetry shell
```

#### Missing Dependencies
```powershell
# Reinstall all dependencies
poetry install --no-cache

# Install optional dependencies
poetry install --extras "audio ml"
```

## 📊 Performance Testing

### Test Audio Import Performance
1. Connect a USB device with audio files
2. Go to **Import** page
3. Select device and click "Scan for Audio Files"
4. Check scan completes without errors
5. Import a few test files
6. Verify files appear in **Recordings** page

### Test AI Processing
1. Import an audio file with speech
2. Wait for transcription to complete
3. Check **Concept Board** for extracted concepts
4. Verify concept connections and embeddings

### Database Performance Test
```powershell
poetry run python -c "
from soundbloom.database.operations import SoundBloomDB
from time import time

db = SoundBloomDB()
start = time()
# Test database operations
elapsed = time() - start
print(f'Database operations took {elapsed:.2f}s')
"
```

## 🖥️ Desktop Integration (Optional)

### Create Desktop Shortcuts

#### SoundBloom Shortcut
1. Right-click desktop → "New" → "Shortcut"
2. Location: `C:\Users\matthew\Programming\SoundBloom\start_soundbloom.bat`
3. Name: "SoundBloom"
4. Right-click shortcut → "Properties" → "Change Icon"
5. Choose an audio/sound icon

#### Quick Access via Start Menu
1. Copy `start_soundbloom.bat` to:
   `%AppData%\Microsoft\Windows\Start Menu\Programs`
2. Rename to "SoundBloom.bat"
3. Now accessible via Start Menu search

### System Tray Integration (Advanced)
For always-on access, consider using a tool like:
- **NSSM** (Non-Sucking Service Manager) to run as Windows service
- **Task Scheduler** for startup automation

## 🔍 Monitoring & Logs

### Check Application Logs
```powershell
# View Reflex logs
Get-Content -Path ".web\reflex.log" -Tail 20 -Wait

# View Neo4j logs (if using Community Edition)
Get-Content -Path "$env:NEO4J_HOME\logs\neo4j.log" -Tail 20
```

### Monitor Resource Usage
```powershell
# Check Python processes
Get-Process | Where-Object {$_.ProcessName -like "*python*"}

# Check port usage
netstat -ano | Select-String ":3000|:7687|:7474"
```

## 🎯 Testing Checklist

- [ ] Python 3.11+ installed and accessible
- [ ] Poetry installed and working
- [ ] Neo4j installed and can start
- [ ] SoundBloom starts without errors
- [ ] Web interface accessible at localhost:3000
- [ ] USB device detection working
- [ ] Audio file import successful
- [ ] Transcription processing working
- [ ] Concept extraction functional
- [ ] Database operations working
- [ ] All pages load without errors

## 📞 Getting Help

If you encounter issues:
1. Check the console output for error messages
2. Verify all prerequisites are installed
3. Check Neo4j is running and accessible
4. Ensure ports 3000 and 7687 are not blocked
5. Try restarting with verbose output: `.\Start-SoundBloom.ps1 -Verbose`

**Success Indicator**: When everything is working, you should be able to:
1. Start SoundBloom with one command/click
2. Access the web interface immediately
3. Import audio files from USB devices
4. See transcriptions and concepts generated automatically
5. Navigate between all pages without errors
