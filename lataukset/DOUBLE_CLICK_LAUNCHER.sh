#!/bin/bash

# ================================================================
# XXMXLI INCIDENT REPORTER - DOUBLE-CLICK LAUNCHER
# ================================================================
# This script makes it super easy to run the incident reporter
# Just double-click this file in your file manager!
# ================================================================

clear
echo "🚀 XXMXLI Incident Reporter - Double-Click Launcher"
echo "=================================================="
echo ""

# Check if we're in a terminal or GUI environment
if [ -t 0 ] && [ -t 1 ]; then
    # Running in terminal
    echo "Running in terminal mode..."
    ./automated_incident_reporter.sh
else
    # Running from double-click (no terminal)
    echo "Opening new terminal window..."
    
    # Try different terminal emulators
    if command -v gnome-terminal >/dev/null 2>&1; then
        gnome-terminal -- bash -c "cd '$(dirname "$0")' && ./automated_incident_reporter.sh; echo ''; echo 'Press Enter to close...'; read"
    elif command -v xterm >/dev/null 2>&1; then
        xterm -e "cd '$(dirname "$0")' && ./automated_incident_reporter.sh; echo ''; echo 'Press Enter to close...'; read"
    elif command -v konsole >/dev/null 2>&1; then
        konsole -e bash -c "cd '$(dirname "$0")' && ./automated_incident_reporter.sh; echo ''; echo 'Press Enter to close...'; read"
    elif command -v terminal >/dev/null 2>&1; then
        terminal -e "cd '$(dirname "$0")' && ./automated_incident_reporter.sh; echo ''; echo 'Press Enter to close...'; read"
    else
        # Fallback - try to run in current context
        echo "No suitable terminal found. Running in background..."
        cd "$(dirname "$0")"
        ./automated_incident_reporter.sh
    fi
fi
