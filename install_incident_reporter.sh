#!/bin/bash
# XXMXLI Incident Reporter Installer - Linux/macOS
# This script installs and configures the incident reporting system

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Get script directory (works regardless of where script is run from)
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo -e "${BLUE}================================================================${NC}"
echo -e "${BLUE}XXMXLI Incident Reporter Installer${NC}"
echo -e "${BLUE}================================================================${NC}"
echo
echo -e "${YELLOW}Installing from: $SCRIPT_DIR${NC}"
echo

# Check Python installation
echo -e "${BLUE}Checking Python installation...${NC}"
if command -v python3 &> /dev/null; then
    PYTHON_CMD="python3"
    echo -e "${GREEN}✓ Python 3 found: $(python3 --version)${NC}"
elif command -v python &> /dev/null; then
    PYTHON_CMD="python"
    echo -e "${GREEN}✓ Python found: $(python --version)${NC}"
else
    echo -e "${RED}✗ Python not found. Please install Python 3.${NC}"
    exit 1
fi

# Check tkinter for GUI applications
echo -e "${BLUE}Checking GUI support...${NC}"
if $PYTHON_CMD -c "import tkinter" 2>/dev/null; then
    echo -e "${GREEN}✓ GUI support available (tkinter found)${NC}"
else
    echo -e "${YELLOW}⚠ GUI support not available. Installing tkinter...${NC}"
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y python3-tk
    elif command -v yum &> /dev/null; then
        sudo yum install -y tkinter
    elif command -v brew &> /dev/null; then
        echo "On macOS, tkinter should be included with Python"
    else
        echo -e "${YELLOW}⚠ Please install tkinter manually for GUI support${NC}"
    fi
fi

# Create necessary directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p "$SCRIPT_DIR/reports"
mkdir -p "$SCRIPT_DIR/logs"
echo -e "${GREEN}✓ Directories created${NC}"

# Set permissions
echo -e "${BLUE}Setting permissions...${NC}"
chmod +x "$SCRIPT_DIR"/*.py
chmod +x "$SCRIPT_DIR"/*.sh
echo -e "${GREEN}✓ Permissions set${NC}"

# Test the incident reporter
echo -e "${BLUE}Testing incident reporter...${NC}"
if $PYTHON_CMD "$SCRIPT_DIR/automated_incident_reporter.py" setup; then
    echo -e "${GREEN}✓ Incident reporter installed successfully${NC}"
else
    echo -e "${RED}✗ Installation test failed${NC}"
    exit 1
fi

# Create desktop launcher (optional)
if command -v xdg-desktop-menu &> /dev/null; then
    echo -e "${BLUE}Creating desktop launcher...${NC}"
    cat > "$SCRIPT_DIR/xxmxli-incident-reporter.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=XXMXLI Incident Reporter
Comment=Security Incident Reporting System
Exec=$PYTHON_CMD "$SCRIPT_DIR/EASY_LAUNCHER.py"
Icon=security
Terminal=false
Categories=Security;System;
EOF
    chmod +x "$SCRIPT_DIR/xxmxli-incident-reporter.desktop"
    echo -e "${GREEN}✓ Desktop launcher created${NC}"
fi

echo
echo -e "${GREEN}================================================================${NC}"
echo -e "${GREEN}INSTALLATION COMPLETE${NC}"
echo -e "${GREEN}================================================================${NC}"
echo
echo -e "${YELLOW}Available launchers:${NC}"
echo -e "  • GUI Launcher: $PYTHON_CMD '$SCRIPT_DIR/EASY_LAUNCHER.py'"
echo -e "  • Main Control: $PYTHON_CMD '$SCRIPT_DIR/XXMXLI_LAUNCHER.py'"
echo -e "  • Direct CLI:   $PYTHON_CMD '$SCRIPT_DIR/automated_incident_reporter.py'"
echo
echo -e "${BLUE}The system is now ready for security incident reporting!${NC}"