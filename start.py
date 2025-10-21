#!/usr/bin/env python3
"""
🌸 SoundBloom - Quick Start
Main entry point for the SoundBloom application.
"""

import subprocess
import sys
import os
from pathlib import Path


def main():
    """Start SoundBloom application."""
    print("🌸 SoundBloom - AI-Powered Concept Analysis")
    print("=" * 50)
    
    # Check if we're in the right directory
    if not Path("SoundBloom/SoundBloom.py").exists():
        print("❌ Error: Please run this script from the SoundBloom root directory")
        sys.exit(1)
    
    # Check for poetry
    try:
        subprocess.run(["poetry", "--version"], check=True, capture_output=True)
    except (subprocess.CalledProcessError, FileNotFoundError):
        print("❌ Error: Poetry not found. Please install Poetry first.")
        print("   Visit: https://python-poetry.org/docs/#installation")
        sys.exit(1)
    
    print("🔧 Starting SoundBloom...")
    print("📱 The application will open in your browser")
    print("⚠️  Press Ctrl+C to stop\n")
    
    try:
        # Try the working demo first
        if Path("examples/soundbloom_demo.py").exists():
            print("🚀 Starting SoundBloom Demo (Guaranteed to work)")
            print("📍 Will be available at: http://localhost:3000")
            subprocess.run([
                "poetry", "run", "python", "examples/soundbloom_demo.py"
            ], check=True)
        else:
            # Fall back to main Reflex app
            print("🚀 Starting SoundBloom Reflex App")
            print("📍 Will be available at: http://localhost:3000")
            subprocess.run([
                "poetry", "run", "reflex", "run", "--frontend-port", "3000"
            ], check=True)
            
    except KeyboardInterrupt:
        print("\n🛑 SoundBloom stopped")
    except subprocess.CalledProcessError as e:
        print(f"❌ Error starting SoundBloom: {e}")
        print("\n💡 Try running the demo instead:")
        print("   poetry run python examples/soundbloom_demo.py")


if __name__ == "__main__":
    main()