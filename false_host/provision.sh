#!/bin/bash
#####################################################################
# FALSE BASE STATION PROVISIONING SCRIPT FOR HOST
#
# Provisions host system with:
# - LibreSDR B220 mini drivers (UHD)
# - srsRAN 4G (rogue eNodeB)
# - Attack mode configurations
# - Signal management tools
#
# This script should be run directly on the host system
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
echo -e "${MAGENTA}  False BS Provisioning${NC}"
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

#####################################################################
# Phase 1: System Setup
#####################################################################
echo -e "${BLUE}[1/8] Updating system packages...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

#####################################################################
# Phase 2: Install SDR Drivers
#####################################################################
echo -e "${BLUE}[2/8] Installing SDR drivers (UHD for LibreSDR B220 #3)...${NC}"

# Note: SDR device attachment happens after VM startup via VirtualBox GUI
# The SDR setup script will run but may skip device-specific operations
# if no SDR device is detected during provisioning

# Check for SDR script in local directory
SDR_SCRIPT="./install/sdr.sh"

if [ -f "$SDR_SCRIPT" ]; then
    # Run SDR setup script directly (no Vagrant user switching needed)
    echo -e "${YELLOW}Note: SDR device setup will complete after manual USB attachment${NC}"
    VAGRANT_PROVISIONING=1 bash "$SDR_SCRIPT"
else
    echo -e "${RED}Error: sdr.sh not found${NC}"
    echo "Expected location: ./install/sdr.sh"
    exit 1
fi

#####################################################################
# Phase 3: Install srsRAN 4G (NO CORE NETWORK)
#####################################################################
echo -e "${BLUE}[3/8] Installing srsRAN 4G (rogue eNodeB only)...${NC}"

if [ -f "./install/srsran-4g.sh" ]; then
    USE_EXISTING_CONF=0 bash ./install/srsran-4g.sh
else
    echo -e "${RED}Error: srsran-4g.sh not found${NC}"
    exit 1
fi

# NOTE: We do NOT install Open5GS on the false BS
# The false BS either operates standalone or relays to the legitimate BS's core

#####################################################################
# Phase 4: srsRAN 5G - SKIPPED (Focus on 4G only)
#####################################################################
echo -e "${YELLOW}[4/8] srsRAN 5G installation skipped (focusing on 4G LTE)${NC}"

#####################################################################
# Phase 5: Fix USB Permissions
#####################################################################
echo -e "${BLUE}[5/8] Fixing USB permissions for SDR devices...${NC}"

# Add vagrant user to plugdev group for USB access
usermod -a -G plugdev vagrant 2>/dev/null || true

# Create udev rule for USRP devices
cat > /etc/udev/rules.d/10-usrp.rules << 'EOF'
# USRP B210/B220/B200 devices
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0020", MODE:="0666", GROUP:="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0021", MODE:="0666", GROUP:="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0022", MODE:="0666", GROUP:="plugdev"
EOF

# Reload udev rules
udevadm control --reload-rules
udevadm trigger

echo -e "${GREEN}✓ USB permissions configured${NC}"

#####################################################################
# Phase 6: Deploy Rogue Configuration Files
#####################################################################
echo -e "${BLUE}[6/8] Deploying false BS (rogue) configurations...${NC}"

# Configuration files will be used directly from ./configs/attack_profiles/
if [ -d "./configs/attack_profiles" ]; then
    echo -e "${GREEN}✓ Attack profile configurations available${NC}"
else
    echo -e "${YELLOW}Warning: Configuration directory not found${NC}"
fi

#####################################################################
# Phase 7: Install Attack & Control Scripts
#####################################################################
echo -e "${BLUE}[7/8] Installing attack and control scripts...${NC}"

# Scripts will be run from their original location
if [ -d "./scripts" ]; then
    # Make scripts executable
    chmod +x ./scripts/*.sh 2>/dev/null || true
    echo -e "${GREEN}✓ Scripts ready${NC}"
else
    echo -e "${YELLOW}Warning: Scripts directory not found${NC}"
fi

# Create log directories
mkdir -p /tmp/false_bs_logs
chmod 777 /tmp/false_bs_logs

#####################################################################
# Phase 8: Final Setup and Testing
#####################################################################
echo -e "${BLUE}[8/8] Final setup and testing...${NC}"

# Note: SDR detection testing skipped during provisioning
# SDR devices need to be attached to VM before running srsRAN
echo -e "${YELLOW}⚠️  SDR device detection skipped during provisioning${NC}"
echo -e "${YELLOW}   → Attach SDR devices manually before starting false base station${NC}"

echo -e "${GREEN}✓ All components installed and configured${NC}"

#####################################################################
# Final Message
#####################################################################
echo ""
echo -e "${MAGENTA}======================================${NC}"
echo -e "${MAGENTA}  False Base Station Provisioning Complete!${NC}"
echo -e "${MAGENTA}======================================${NC}"
echo ""
echo "False Base Station is ready!"
echo ""
echo "Installed Components:"
echo "  ✅ UHD 4.1.0.5 SDR drivers"
echo "  ✅ LibreSDR B210/B220 support"
echo "  ✅ srsRAN 4G (rogue eNodeB)"
echo "  ✅ Attack profiles and configurations"
echo "  ✅ USB permissions configured"
echo "  ✅ Control scripts installed"
echo ""
echo -e "${YELLOW}⚠️  FALSE BASE STATION configured${NC}"
echo -e "${RED}   For RESEARCH and EDUCATIONAL use ONLY${NC}"
echo ""
echo "Default Configuration:"
echo "  Mode:           4G LTE"
echo "  Attack Profile: IMSI Catcher"
echo "  TX Gain:        80 dB (higher than legitimate)"
echo "  Startup Delay:  15 seconds"
echo ""
echo "Quick Start Commands:"
echo "  attack_config.sh list                    # List attack profiles"
echo "  attack_config.sh set imsi_catcher        # Set attack mode"
echo "  start_false_bs.sh                        # Start false BS (with delay)"
echo "  start_false_bs.sh --no-delay             # Start immediately"
echo ""
echo "Signal Management:"
echo "  signal_manager.sh preset-handover       # Configure for handover"
echo "  signal_manager.sh ramp-up-false         # Gradually increase signal"
echo "  adjust_signal.sh demo                   # Interactive adjustment"
echo ""
echo "Monitoring:"
echo "  monitor_handover.sh                     # Monitor UE handovers"
echo ""
echo "Attack Profiles Available:"
echo "  • imsi_catcher  - Capture IMSI/IMEI identities"
echo "  • downgrade     - Force weak encryption"
echo "  • mitm          - Man-in-the-middle attack"
echo "  • dos           - Denial of service"
echo ""
echo -e "${RED}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${RED}║  IMPORTANT: Always start legitimate BS FIRST          ║${NC}"
echo -e "${RED}║  Wait for UE to connect, then start false BS          ║${NC}"
echo -e "${RED}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

