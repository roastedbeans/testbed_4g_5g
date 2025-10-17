#!/bin/bash
#####################################################################
# FALSE BASE STATION PROVISIONING SCRIPT
#
# Provisions VM with:
# - LibreSDR B220 mini drivers (UHD)
# - srsRAN 4G (rogue eNodeB)
# - srsRAN 5G (rogue gNodeB)
# - Attack mode configurations
# - Signal management tools
#
# NO CORE NETWORK - False BS operates standalone or relays to real core
#
# This script should be run during Vagrant provisioning
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
echo -e "${BLUE}[1/7] Updating system packages...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get upgrade -y -qq

#####################################################################
# Phase 2: Install SDR Drivers
#####################################################################
echo -e "${BLUE}[2/7] Installing SDR drivers (UHD for LibreSDR B220 #3)...${NC}"

# The SDR script must run as vagrant user, not root
# Copy the script and run it as the vagrant user
# Try multiple possible paths since /vagrant may not be available
SDR_SCRIPT=""
for path in "/vagrant/install/sdr.sh" "/vagrant/sdr.sh" "./sdr.sh" "../sdr.sh" "/home/ubuntu-chan/Documents/Github/airgap/attacks/sdr.sh"; do
    if [ -f "$path" ]; then
        SDR_SCRIPT="$path"
        break
    fi
done

if [ -n "$SDR_SCRIPT" ]; then
    cp "$SDR_SCRIPT" /tmp/
    chmod +x /tmp/sdr.sh

    # Run as vagrant user
    su -c "cd /tmp && ./sdr.sh" vagrant
else
    echo -e "${RED}Error: sdr.sh not found in any expected location${NC}"
    echo "Searched: /vagrant/sdr.sh, ./sdr.sh, ../sdr.sh, /home/ubuntu-chan/Documents/Github/airgap/attacks/sdr.sh"
    exit 1
fi

#####################################################################
# Phase 3: Install srsRAN 4G (NO CORE NETWORK)
#####################################################################
echo -e "${BLUE}[3/7] Installing srsRAN 4G (rogue eNodeB only)...${NC}"

if [ -f "/vagrant/install/srsran-4g.sh" ]; then
    cp /vagrant/install/srsran-4g.sh /tmp/
    chmod +x /tmp/srsran-4g.sh
    cd /tmp && USE_EXISTING_CONF=0 ./srsran-4g.sh
else
    echo -e "${RED}Error: srsran-4g.sh not found${NC}"
    exit 1
fi

# NOTE: We do NOT install Open5GS on the false BS
# The false BS either operates standalone or relays to the legitimate BS's core

#####################################################################
# Phase 4: srsRAN 5G - SKIPPED (Focus on 4G only)
#####################################################################
echo -e "${YELLOW}[4/7] srsRAN 5G installation skipped (focusing on 4G LTE)${NC}"

#####################################################################
# Phase 5: Fix USB Permissions
#####################################################################
echo -e "${BLUE}[5/7] Fixing USB permissions for SDR devices...${NC}"

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
echo -e "${BLUE}[6/7] Deploying false BS (rogue) configurations...${NC}"

# Create srsRAN config directories
mkdir -p /etc/srsran/false

# Copy 4G attack profile configurations
if [ -d "/vagrant/configs/attack_profiles" ]; then
    cp /vagrant/configs/attack_profiles/enb_4g_rogue.conf /etc/srsran/false/enb.conf 2>/dev/null || true
    cp /vagrant/configs/attack_profiles/rr.conf /etc/srsran/false/rr.conf 2>/dev/null || true
    cp /vagrant/configs/attack_profiles/rb.conf /etc/srsran/false/rb.conf 2>/dev/null || true
    cp /vagrant/configs/attack_profiles/sib.conf /etc/srsran/false/sib.conf 2>/dev/null || true
    echo -e "${GREEN}✓ 4G attack profile configurations deployed${NC}"

    # Copy attack modes configuration
    mkdir -p /opt/configs/false
    cp /vagrant/configs/attack_profiles/attack_modes.conf /opt/configs/false/ 2>/dev/null || true
    echo -e "${GREEN}✓ Attack modes configuration deployed${NC}"
else
    echo -e "${YELLOW}Warning: Configuration directory not found${NC}"
fi

# Copy attack profiles
if [ -d "/vagrant/configs/attack_profiles" ]; then
    mkdir -p /opt/attack_profiles
    cp /vagrant/configs/attack_profiles/*.conf /opt/attack_profiles/ 2>/dev/null || true
    chmod 644 /opt/attack_profiles/*.conf 2>/dev/null || true
    echo -e "${GREEN}✓ Attack profiles deployed${NC}"
else
    echo -e "${YELLOW}Warning: Attack profiles directory not found${NC}"
fi

#####################################################################
# Phase 7: Install Attack & Control Scripts
#####################################################################
echo -e "${BLUE}[7/7] Installing attack and control scripts...${NC}"

# Create scripts directory
mkdir -p /opt/scripts

# Copy scripts
if [ -d "/vagrant/scripts" ]; then
    cp /vagrant/scripts/start_false_bs.sh /opt/scripts/ 2>/dev/null || true
    cp /vagrant/scripts/signal_manager.sh /opt/scripts/ 2>/dev/null || true
    cp /vagrant/scripts/monitor_handover.sh /opt/scripts/ 2>/dev/null || true
    cp /vagrant/scripts/adjust_signal.sh /opt/scripts/ 2>/dev/null || true
    cp /vagrant/scripts/attack_config.sh /opt/scripts/ 2>/dev/null || true
    
    # Make scripts executable
    chmod +x /opt/scripts/*.sh 2>/dev/null || true
    
    echo -e "${GREEN}✓ Scripts installed${NC}"
else
    echo -e "${YELLOW}Warning: Scripts directory not found${NC}"
fi

# Add scripts to PATH
if ! grep -q "/opt/scripts" /etc/environment; then
    echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/scripts"' > /etc/environment
fi

# Create log directories
mkdir -p /tmp/false_bs_logs
chmod 777 /tmp/false_bs_logs

#####################################################################
# Final Setup
#####################################################################
echo ""
echo -e "${MAGENTA}======================================${NC}"
echo -e "${MAGENTA}  Provisioning Complete!${NC}"
echo -e "${MAGENTA}======================================${NC}"
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

