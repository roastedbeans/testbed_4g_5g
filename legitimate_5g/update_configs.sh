#!/bin/bash

#####################################################################
# Update Legitimate 5G BS Configs Without Reprovisioning
#
# This script copies updated configuration files from the host
# /vagrant/configs/srsran/ directories to the VM system directories
# where srsRAN reads them (/etc/srsran/legitimate/)
#
# Usage: ./update_configs.sh
#####################################################################

set -e

echo "════════════════════════════════════════════════════════════"
echo "  Updating Legitimate 5G Base Station Configurations"
echo "════════════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if running inside VM
if [ -d "/vagrant" ]; then
    echo -e "${YELLOW}Running inside VM...${NC}"

    # Verify source directories exist
    if [ ! -d "/vagrant/configs/srsran" ]; then
        echo -e "${RED}Error: Source directory /vagrant/configs/srsran not found${NC}"
        exit 1
    fi

    # Create backup directories if they don't exist
    echo "Creating backup directories..."
    sudo mkdir -p /etc/srsran/legitimate/backup

    # Backup existing configs
    echo "Creating backups..."
    sudo cp -r /etc/srsran/legitimate/* /etc/srsran/legitimate/backup/ 2>/dev/null || true

    # Copy 5G configurations (primary focus)
    echo "Updating 5G gNodeB configs..."
    sudo cp /vagrant/configs/srsran/gnb.conf /etc/srsran/legitimate/gnb_5g.conf 2>/dev/null || true
    echo -e "${GREEN}✓ 5G gNodeB configurations updated${NC}"

    # Copy 4G configurations (secondary)
    echo "Updating 4G eNodeB configs..."
    sudo cp /vagrant/configs/srsran/enb.conf /etc/srsran/legitimate/enb_4g.conf 2>/dev/null || true
    sudo cp /vagrant/configs/srsran/rr.conf /etc/srsran/legitimate/rr.conf 2>/dev/null || true
    sudo cp /vagrant/configs/srsran/rb.conf /etc/srsran/legitimate/rb.conf 2>/dev/null || true
    sudo cp /vagrant/configs/srsran/sib.conf /etc/srsran/legitimate/sib.conf 2>/dev/null || true
    echo -e "${GREEN}✓ 4G eNodeB configurations updated${NC}"

    # Copy Open5GS configurations (supports both 4G and 5G)
    echo "Updating Open5GS configs..."
    sudo cp /vagrant/configs/open5gs/mme.yaml /etc/open5gs/mme.yaml 2>/dev/null || true
    sudo cp /vagrant/configs/open5gs/amf.yaml /etc/open5gs/amf.yaml 2>/dev/null || true
    echo -e "${GREEN}✓ Open5GS configurations updated (4G MME + 5G AMF)${NC}"

    echo ""
    echo -e "${GREEN}✅ Configuration files updated successfully!${NC}"
    echo ""
    echo "Files copied:"
    echo "  • /vagrant/configs/srsran/gnb.conf → /etc/srsran/legitimate/gnb_5g.conf"
    echo "  • /vagrant/configs/srsran/enb.conf → /etc/srsran/legitimate/enb_4g.conf"
    echo "  • /vagrant/configs/srsran/rr.conf → /etc/srsran/legitimate/rr.conf"
    echo "  • /vagrant/configs/srsran/rb.conf → /etc/srsran/legitimate/rb.conf"
    echo "  • /vagrant/configs/srsran/sib.conf → /etc/srsran/legitimate/sib.conf"
    echo "  • /vagrant/configs/open5gs/mme.yaml → /etc/open5gs/mme.yaml"
    echo "  • /vagrant/configs/open5gs/amf.yaml → /etc/open5gs/amf.yaml"
    echo ""
    echo "Backups created in:"
    echo "  • /etc/srsran/legitimate/backup/"
    echo ""
    echo "Next steps:"
    echo "  1. If base stations are running, restart them:"
    echo "     sudo pkill srsenb && sudo pkill gnb"
    echo "     sudo srsenb /etc/srsran/legitimate/gnb_5g.conf &  # 5G (primary)"
    echo "     sudo srsenb /etc/srsran/legitimate/enb_4g.conf &  # 4G (secondary)"
    echo ""
    echo "  2. Verify configs are loaded:"
    echo "     grep 'amf_addr' /etc/srsran/legitimate/gnb_5g.conf  # 5G AMF connection"
    echo "     grep 'mme_addr' /etc/srsran/legitimate/enb_4g.conf  # 4G MME connection"

else
    # Running from host - execute command in VM
    echo -e "${YELLOW}Running from host, executing in VM...${NC}"

    # Check if VM is running
    if ! vagrant status | grep -q "running"; then
        echo -e "${RED}Error: VM is not running. Please start it with 'vagrant up' first.${NC}"
        exit 1
    fi

    # Execute this script inside the VM
    vagrant ssh -c "bash /vagrant/update_configs.sh"
fi

echo ""
echo "════════════════════════════════════════════════════════════"
