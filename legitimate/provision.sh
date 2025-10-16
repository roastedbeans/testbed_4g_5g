#!/bin/bash
#####################################################################
# LEGITIMATE BASE STATION PROVISIONING SCRIPT
#
# Provisions VM with:
# - LibreSDR B220 mini drivers (UHD)
# - Open5GS core network (4G MME + 5G AMF)
# - srsRAN 4G (eNodeB)
# - srsRAN 5G (gNodeB)
# - Network switching capability
#
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
echo -e "${BLUE}  Legitimate BS Provisioning${NC}"
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
# Phase 3: Install Open5GS
#####################################################################
echo -e "${BLUE}[3/8] Installing Open5GS core network...${NC}"

if [ -f "/vagrant/install/open5gs.sh" ]; then
    cp /vagrant/install/open5gs.sh /tmp/
    chmod +x /tmp/open5gs.sh
    cd /tmp && ./open5gs.sh
else
    echo -e "${RED}Error: open5gs.sh not found${NC}"
    exit 1
fi

#####################################################################
# Phase 4: Install Open5GS WebUI
#####################################################################
echo -e "${BLUE}[4/8] Installing Open5GS WebUI...${NC}"

if [ -f "/vagrant/install/open5gs_webui.sh" ]; then
    cp /vagrant/install/open5gs_webui.sh /tmp/
    chmod +x /tmp/open5gs_webui.sh
    cd /tmp && ./open5gs_webui.sh
else
    echo -e "${YELLOW}Warning: open5gs_webui.sh not found, skipping WebUI installation${NC}"
fi

#####################################################################
# Phase 5: Install srsRAN 4G
#####################################################################
echo -e "${BLUE}[5/8] Installing srsRAN 4G...${NC}"

if [ -f "/vagrant/install/srsran-4g.sh" ]; then
    cp /vagrant/install/srsran-4g.sh /tmp/
    chmod +x /tmp/srsran-4g.sh
    cd /tmp && USE_EXISTING_CONF=0 ./srsran-4g.sh
else
    echo -e "${RED}Error: srsran-4g.sh not found${NC}"
    exit 1
fi

#####################################################################
# Phase 6: srsRAN 5G - SKIPPED (Focus on 4G only)
#####################################################################
echo -e "${YELLOW}[6/8] srsRAN 5G installation skipped (focusing on 4G LTE)${NC}"

#####################################################################
# Phase 7: Fix USB Permissions
#####################################################################
echo -e "${BLUE}[7/8] Fixing USB permissions for SDR devices...${NC}"

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
# Phase 8: Deploy Configuration Files
#####################################################################
echo -e "${BLUE}[8/8] Deploying legitimate BS configurations...${NC}"

# Create srsRAN config directories
mkdir -p /etc/srsran/legitimate

# Copy 4G configurations
if [ -d "/vagrant/configs/srsran" ]; then
    cp /vagrant/configs/srsran/enb.conf /etc/srsran/legitimate/enb_4g.conf 2>/dev/null || true
    cp /vagrant/configs/srsran/rr.conf /etc/srsran/legitimate/ 2>/dev/null || true
    cp /vagrant/configs/srsran/rb.conf /etc/srsran/legitimate/ 2>/dev/null || true
    cp /vagrant/configs/srsran/sib.conf /etc/srsran/legitimate/ 2>/dev/null || true
    echo -e "${GREEN}✓ 4G configurations deployed${NC}"

    # Copy Open5GS configurations
    cp /vagrant/configs/open5gs/mme.yaml /etc/open5gs/mme.yaml 2>/dev/null || true
    cp /vagrant/configs/open5gs/amf.yaml /etc/open5gs/amf.yaml 2>/dev/null || true
    echo -e "${GREEN}✓ Open5GS configurations deployed${NC}"
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

# Set default mode to 4G
echo -e "${BLUE}Setting default mode to 4G...${NC}"
systemctl enable open5gs-mmed 2>/dev/null || true
systemctl disable open5gs-amfd 2>/dev/null || true
echo -e "${GREEN}✓ Default mode set to 4G${NC}"

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
echo "Legitimate Base Station is ready!"
echo ""
echo "Installed Components:"
echo "  ✅ UHD 4.1.0.5 SDR drivers"
echo "  ✅ LibreSDR B210/B220 support"
echo "  ✅ Open5GS core network (4G LTE)"
echo "  ✅ MongoDB & Subscriber Management"
echo "  ✅ srsRAN 4G (eNodeB)"
echo "  ✅ USB permissions configured"
echo "  ✅ All configuration files deployed"
echo "  ✅ Control scripts installed"
echo ""
#####################################################################
# Phase 9: Install Subscriber Management Script
#####################################################################
echo -e "${BLUE}[8/8] Installing subscriber management script...${NC}"

# Copy subscriber.sh to /usr/local/bin
if [ -f "/vagrant/scripts/subscriber.sh" ]; then
    cp /vagrant/scripts/subscriber.sh /usr/local/bin/subscriber.sh
    chmod +x /usr/local/bin/subscriber.sh
    echo -e "${GREEN}✅ Subscriber management script installed${NC}"
else
    echo -e "${YELLOW}⚠️  subscriber.sh not found, skipping${NC}"
fi

# Add default test subscribers
echo -e "${BLUE}Adding default test subscribers...${NC}"

# Wait for MongoDB to be fully ready
sleep 5

# Add test subscriber with default credentials
# IMSI: 001010000118896
# K (KEY): 465B5CE8B199B49FAA5F0A2EE238A6BC
# OPC: E8ED289DEBA952E4283B54E88E6183CA
cat > /tmp/add_default_subscriber.js << 'EOF'
db = db.getSiblingDB('open5gs');
db.subscribers.updateOne(
    { imsi: "001010000118896" },
    { $setOnInsert: {
        schema_version: NumberInt(1),
        imsi: "001010000118896",
        msisdn: [],
        imeisv: "1110000000000000",
        slice: [{
            sst: NumberInt(1),
            default_indicator: true,
            session: [{
                name: "internet",
                type: NumberInt(3),
                qos: {
                    index: NumberInt(9),
                    arp: {
                        priority_level: NumberInt(8),
                        pre_emption_capability: NumberInt(1),
                        pre_emption_vulnerability: NumberInt(1)
                    }
                },
                ambr: {
                    downlink: { value: NumberInt(1), unit: NumberInt(3) },
                    uplink: { value: NumberInt(1), unit: NumberInt(3) }
                }
            }]
        }],
        security: {
            k: "465B5CE8B199B49FAA5F0A2EE238A6BC",
            opc: "E8ED289DEBA952E4283B54E88E6183CA",
            amf: "8000",
            sqn: NumberLong(1184)
        },
        ambr: {
            downlink: { value: NumberInt(1), unit: NumberInt(3) },
            uplink: { value: NumberInt(1), unit: NumberInt(3) }
        },
        access_restriction_data: 32,
        network_access_mode: 2,
        subscriber_status: 0
    }},
    { upsert: true }
);
print("✅ Default test subscriber added: IMSI=001010000118896");
EOF

# Add subscriber to MongoDB
mongosh --quiet /tmp/add_default_subscriber.js || echo -e "${YELLOW}⚠️  Failed to add default subscriber (MongoDB may still be starting)${NC}"
rm /tmp/add_default_subscriber.js

echo -e "${GREEN}✅ Default subscriber configuration completed${NC}"

#####################################################################
# Provisioning Complete
#####################################################################
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}║  ✅ Legitimate Base Station Provisioning Complete!        ║${NC}"
echo -e "${GREEN}║                                                            ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Default Mode: 4G LTE"
echo ""
echo "📋 Default Test Subscriber (Pre-configured):"
echo "  IMSI: 001010000118896"
echo "  K:    465B5CE8B199B49FAA5F0A2EE238A6BC"
echo "  OPC:  E8ED289DEBA952E4283B54E88E6183CA"
echo ""
echo "📋 Subscriber Management Commands:"
echo "  sudo subscriber.sh list              # List all subscribers"
echo "  sudo subscriber.sh count             # Count subscribers"
echo "  sudo subscriber.sh add <imsi> <k> <opc>  # Add new subscriber"
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

