#!/bin/bash

#####################################################################
# Update Legitimate BS Configs Without Reprovisioning
#
# This script copies updated configuration files from the host
# /vagrant/configs/srsran/ directories to the VM system directories
# where srsRAN reads them (/etc/srsran/legitimate/ and /etc/srsran/legitimate2/)
#
# Usage: ./update_configs.sh
#####################################################################

set -e

echo "════════════════════════════════════════════════════════════"
echo "  Updating Legitimate Base Station Configurations"
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
    if [ ! -d "/vagrant/configs/srsran/legitimate" ]; then
        echo -e "${RED}Error: Source directory /vagrant/configs/srsran/legitimate not found${NC}"
        exit 1
    fi

    if [ ! -d "/vagrant/configs/srsran/legitimate2" ]; then
        echo -e "${RED}Error: Source directory /vagrant/configs/srsran/legitimate2 not found${NC}"
        exit 1
    fi

    # Create backup directories if they don't exist
    echo "Creating backup directories..."
    sudo mkdir -p /etc/srsran/legitimate/backup
    sudo mkdir -p /etc/srsran/legitimate2/backup

    # Backup existing configs
    echo "Creating backups..."
    sudo cp -r /etc/srsran/legitimate/* /etc/srsran/legitimate/backup/ 2>/dev/null || true
    sudo cp -r /etc/srsran/legitimate2/* /etc/srsran/legitimate2/backup/ 2>/dev/null || true

    # Copy legitimate BS configs (SDR #1 - C5XA7X9)
    echo "Updating legitimate (PCI=1) configs..."
    sudo cp /vagrant/configs/srsran/legitimate/enb.conf /etc/srsran/legitimate/enb_4g.conf
    sudo cp /vagrant/configs/srsran/legitimate/rr.conf /etc/srsran/legitimate/rr.conf
    sudo cp /vagrant/configs/srsran/legitimate/sib.conf /etc/srsran/legitimate/sib.conf
    sudo cp /vagrant/configs/srsran/legitimate/rb.conf /etc/srsran/legitimate/rb.conf

    # Copy legitimate2 BS configs (SDR #2 - P44SEGH)
    echo "Updating legitimate2 (PCI=2) configs..."
    sudo cp /vagrant/configs/srsran/legitimate2/enb.conf /etc/srsran/legitimate2/enb_4g.conf
    sudo cp /vagrant/configs/srsran/legitimate2/rr.conf /etc/srsran/legitimate2/rr.conf
    sudo cp /vagrant/configs/srsran/legitimate2/sib.conf /etc/srsran/legitimate2/sib.conf
    sudo cp /vagrant/configs/srsran/legitimate2/rb.conf /etc/srsran/legitimate2/rb.conf

    echo ""
    echo -e "${GREEN}✅ Configuration files updated successfully!${NC}"
    echo ""
    echo "Files copied:"
    echo "  • /vagrant/configs/srsran/legitimate/ → /etc/srsran/legitimate/"
    echo "  • /vagrant/configs/srsran/legitimate2/ → /etc/srsran/legitimate2/"
    echo ""
    echo "Backups created in:"
    echo "  • /etc/srsran/legitimate/backup/"
    echo "  • /etc/srsran/legitimate2/backup/"
    echo ""
    echo "Next steps:"
    echo "  1. If base stations are running, restart them:"
    echo "     sudo pkill srsenb"
    echo "     sudo srsenb /etc/srsran/legitimate/enb_4g.conf &"
    echo "     sudo srsenb /etc/srsran/legitimate2/enb_4g.conf &"
    echo ""
    echo "  2. Verify configs are loaded:"
    echo "     grep 'enb_id' /etc/srsran/legitimate/enb_4g.conf"
    echo "     grep 'enb_id' /etc/srsran/legitimate2/enb_4g.conf"

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
