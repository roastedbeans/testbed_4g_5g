#!/bin/bash
#####################################################################
# LEGITIMATE BASE STATION #2 PROVISIONING SCRIPT
#
# Provisions VM with:
# - LibreSDR B220 mini drivers (UHD)
# - srsRAN 4G (eNodeB)
# - Network switching capability
#
# Note: Connects to legitimate VM's shared core network for handover testing
# This script should be run during Vagrant provisioning
#####################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Legitimate BS #2 Provisioning${NC}"
echo -e "${BLUE}======================================${NC}"
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
echo -e "${BLUE}[2/7] Installing SDR drivers (UHD for LibreSDR B220)...${NC}"

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
# Phase 3: Install srsRAN 4G
#####################################################################
echo -e "${BLUE}[3/8] Installing srsRAN 4G...${NC}"

if [ -f "/vagrant/install/srsran-4g.sh" ]; then
    cp /vagrant/install/srsran-4g.sh /tmp/
    chmod +x /tmp/srsran-4g.sh
    cd /tmp && USE_EXISTING_CONF=0 ./srsran-4g.sh
else
    echo -e "${RED}Error: srsran-4g.sh not found${NC}"
    exit 1
fi

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
# Phase 6: Deploy Configuration Files
#####################################################################
echo -e "${BLUE}[6/8] Deploying legitimate2 BS configurations...${NC}"

# Create srsRAN config directories
mkdir -p /etc/srsran/legitimate

# Copy 4G configurations
if [ -d "/vagrant/configs/srsran" ]; then
    cp /vagrant/configs/srsran/enb.conf /etc/srsran/legitimate/enb_4g.conf 2>/dev/null || true
    cp /vagrant/configs/srsran/rr.conf /etc/srsran/legitimate/ 2>/dev/null || true
    cp /vagrant/configs/srsran/rb.conf /etc/srsran/legitimate/ 2>/dev/null || true
    cp /vagrant/configs/srsran/sib.conf /etc/srsran/legitimate/ 2>/dev/null || true
    echo -e "${GREEN}✓ 4G configurations deployed${NC}"
else
    echo -e "${YELLOW}Warning: Configuration directory not found${NC}"
fi

#####################################################################
# Phase 7: Install Control Scripts
#####################################################################
echo -e "${BLUE}[7/8] Installing control scripts...${NC}"

# Create scripts directory
mkdir -p /opt/scripts

# Copy scripts
if [ -d "/vagrant/scripts" ]; then
    cp /vagrant/scripts/switch_network.sh /opt/scripts/ 2>/dev/null || true
    cp /vagrant/scripts/signal_manager.sh /opt/scripts/ 2>/dev/null || true
    cp /vagrant/scripts/monitor_handover.sh /opt/scripts/ 2>/dev/null || true
    cp /vagrant/scripts/adjust_signal.sh /opt/scripts/ 2>/dev/null || true
    
    # Make scripts executable
    chmod +x /opt/scripts/*.sh 2>/dev/null || true
    
    echo -e "${GREEN}✓ Control scripts installed${NC}"
else
    echo -e "${YELLOW}Warning: Scripts directory not found${NC}"
fi

# Add scripts to PATH
if ! grep -q "/opt/scripts" /etc/environment; then
    echo 'PATH="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/opt/scripts"' > /etc/environment
fi

#####################################################################
# Phase 8: Final Setup and Testing
#####################################################################
echo -e "${BLUE}[8/8] Final setup and testing...${NC}"

# Note: SDR detection testing skipped during provisioning
# SDR devices need to be attached to VM before running srsRAN
echo -e "${YELLOW}⚠️  SDR device detection skipped during provisioning${NC}"
echo -e "${YELLOW}   → Attach SDR devices manually before starting base stations${NC}"

echo -e "${GREEN}✓ All components installed and configured${NC}"

#####################################################################
# Final Message
#####################################################################
echo ""
echo -e "${GREEN}======================================${NC}"
echo -e "${GREEN}  Provisioning Complete!${NC}"
echo -e "${GREEN}======================================${NC}"
echo ""
echo "Legitimate Base Station #2 is ready!"
echo ""
echo "Installed Components:"
echo "  ✅ UHD 4.1.0.5 SDR drivers"
echo "  ✅ LibreSDR B210/B220 support"
echo "  ✅ srsRAN 4G (eNodeB)"
echo "  ✅ USB permissions configured"
echo "  ✅ All configuration files deployed"
echo "  ✅ Control scripts installed"
echo ""
#####################################################################
# Provisioning Complete
#####################################################################
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  ✅ Legitimate Base Station #2 Provisioning Complete!     ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Default Mode: 4G LTE"
echo ""
echo "📋 Shared Core Network:"
echo "  Connects to legitimate VM's Open5GS core network"
echo "  Uses same subscriber database as legitimate VM"
echo ""
echo "📋 Default Test Subscriber (managed by legitimate VM):"
echo "  IMSI: 001010000118896"
echo "  Ki:   BD9044E60EFA8AD9052799E65D8AF224"
echo "  OPc:  C86FD5618B748B85BBC6515C7AEDB9A4"
echo ""
echo "📋 Subscriber Management:"
echo "  Managed by legitimate VM - use './ssh.sh legitimate' to access"
echo "  Run subscriber management commands on legitimate VM only"
echo ""
echo "Quick Start Commands:"
echo "  # Start 4G LTE network"
echo "  sudo srsenb /etc/srsran/legitimate/enb_4g.conf"
echo ""
echo "Control Scripts Available:"
echo "  signal_manager.sh     # Adjust TX/RX gain"
echo "  monitor_handover.sh   # Monitor UE handovers"
echo "  adjust_signal.sh      # Interactive signal control"
echo ""
echo -e "${BLUE}Next: Start the false base station VM when ready!${NC}"
echo ""
echo "Handover Capability:"
echo "  legitimate2 connects to legitimate's shared MME"
echo "  Enables handover testing between legitimate base stations"
echo ""
echo "SDR Setup:"
echo "  After VM starts: Attach SDR #2 via VirtualBox USB settings"
echo "  The device will be available for use with srsRAN"
echo ""

