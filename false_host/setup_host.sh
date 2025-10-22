#!/bin/bash
#####################################################################
# FALSE BASE STATION HOST SETUP SCRIPT
#
# Sets up and runs the false base station directly on the host system
# This script replaces Vagrant provisioning for direct host installation
#
# Usage: ./setup_host.sh
#####################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}======================================${NC}"
echo -e "${MAGENTA}  False Base Station Host Setup${NC}"
echo -e "${MAGENTA}  ⚠️  RESEARCH USE ONLY ⚠️${NC}"
echo -e "${MAGENTA}======================================${NC}"
echo ""

#####################################################################
# Legal Warning
#####################################################################
echo -e "${RED}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║                  LEGAL WARNING                         ║"
echo "╠════════════════════════════════════════════════════════╣"
echo "║  Operating a false base station is ILLEGAL without    ║"
echo "║  proper authorization. This system is for CONTROLLED   ║"
echo "║  RESEARCH ENVIRONMENTS ONLY.                           ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}[ERROR]${NC} This script should not be run as root. Please run as a normal user."
   exit 1
fi

# Check for sudo privileges
if ! sudo -v; then
    echo -e "${RED}[ERROR]${NC} This script requires sudo privileges"
    exit 1
fi

echo -e "${BLUE}Starting False Base Station setup on host...${NC}"
echo ""

#####################################################################
# Run the provisioning script
#####################################################################
echo -e "${BLUE}Running provisioning script...${NC}"
if [ -f "./provision.sh" ]; then
    bash ./provision.sh
else
    echo -e "${RED}[ERROR]${NC} provision.sh not found in current directory"
    exit 1
fi

#####################################################################
# Setup complete
#####################################################################
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Host Setup Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "False Base Station is ready to run on your host system!"
echo ""
echo "Next steps:"
echo "1. Attach your LibreSDR device (SDR #3)"
echo "2. Configure SDR serial in ./.sdr_config if needed"
echo "3. Run: ./scripts/attack_config.sh list          # List attack profiles"
echo "4. Run: ./scripts/attack_config.sh set imsi_catcher  # Set attack mode"
echo "5. Run: ./scripts/start_false_bs.sh              # Start false BS"
echo ""
echo -e "${YELLOW}⚠️  Remember to start legitimate BS first!${NC}"
echo ""

#####################################################################
# Create desktop shortcuts (optional)
#####################################################################
echo -e "${BLUE}Creating desktop shortcuts...${NC}"

# Create desktop directory if it doesn't exist
mkdir -p ~/Desktop

# Create start script
cat > ~/Desktop/start_false_bs.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Start False Base Station
Comment=Start the rogue base station for research
Exec=bash -c "cd /path/to/false_host && ./scripts/start_false_bs.sh"
Icon=network
Terminal=true
Categories=Network;
EOF

# Create attack config script
cat > ~/Desktop/attack_config.desktop << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Attack Configuration
Comment=Configure attack profiles for false BS
Exec=bash -c "cd /path/to/false_host && ./scripts/attack_config.sh"
Icon=preferences-system
Terminal=true
Categories=Settings;
EOF

chmod +x ~/Desktop/*.desktop
echo -e "${GREEN}✓ Desktop shortcuts created${NC}"
echo ""
echo -e "${YELLOW}Note: Update the path in desktop shortcuts to match your false_host directory location${NC}"
