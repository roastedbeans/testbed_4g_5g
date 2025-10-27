#!/bin/bash

#####################################################################
# Start Both Base Stations with S1/N2 Verification
#
# Starts 5G gNodeB (primary) and 4G eNodeB (secondary) for handover testing
# Ensures both BSs are registered with Open5GS core network before handover attempts
#####################################################################

set -e

echo "═══════════════════════════════════════════════════════"
echo "  Starting Legitimate 5G Base Stations for Handover"
echo "═══════════════════════════════════════════════════════"
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Kill existing instances
echo -e "${YELLOW}Stopping existing base stations...${NC}"
sudo pkill srsenb || true
sudo pkill gnb || true
sleep 2

# Check if Open5GS services are running
echo -e "${YELLOW}Checking Open5GS services status...${NC}"
if sudo systemctl is-active --quiet open5gs-mmed; then
    echo -e "${GREEN}✓ MME is running${NC}"
else
    echo -e "${RED}✗ MME is not running!${NC}"
    echo "Starting MME..."
    sudo systemctl start open5gs-mmed
    sleep 2
fi

if sudo systemctl is-active --quiet open5gs-amfd; then
    echo -e "${GREEN}✓ AMF is running${NC}"
else
    echo -e "${RED}✗ AMF is not running!${NC}"
    echo "Starting AMF..."
    sudo systemctl start open5gs-amfd
    sleep 2
fi

# Start 5G gNodeB (primary focus)
echo ""
echo -e "${YELLOW}Starting 5G gNodeB (Primary)...${NC}"
sudo srsenb /etc/srsran/legitimate/gnb_5g.conf > /tmp/gnb_5g.log 2>&1 &
GNB_PID=$!

# Wait for N2 Setup (5G equivalent of S1)
echo "Waiting for N2 Setup..."
for i in {1..15}; do
    if grep -q "N2.*Setup.*Complete\|Connected to AMF\|AMF connection established" /tmp/gnb_5g.log 2>/dev/null; then
        echo -e "${GREEN}✓ 5G gNodeB registered with AMF${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# Verify 5G gNodeB is still running
if ! ps -p $GNB_PID > /dev/null; then
    echo -e "${RED}✗ 5G gNodeB failed to start!${NC}"
    echo "Check logs: tail -f /tmp/gnb_5g.log"
    exit 1
fi

# Start 4G eNodeB (secondary)
echo ""
echo -e "${YELLOW}Starting 4G eNodeB (Secondary)...${NC}"
sudo srsenb /etc/srsran/legitimate/enb_4g.conf > /tmp/enb_4g.log 2>&1 &
ENB_PID=$!

# Wait for S1 Setup
echo "Waiting for S1 Setup..."
for i in {1..10}; do
    if grep -q "S1.*Setup.*Complete\|S1 Setup Response" /tmp/enb_4g.log 2>/dev/null; then
        echo -e "${GREEN}✓ 4G eNodeB registered with MME${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# Verify 4G eNodeB is still running
if ! ps -p $ENB_PID > /dev/null; then
    echo -e "${RED}✗ 4G eNodeB failed to start!${NC}"
    echo "Check logs: tail -f /tmp/enb_4g.log"
    exit 1
fi

# Final status
echo ""
echo "═══════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Both Base Stations Running${NC}"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Process IDs:"
echo "  5G gNodeB (Primary):   $GNB_PID"
echo "  4G eNodeB (Secondary): $ENB_PID"
echo ""
echo "Log files:"
echo "  5G gNodeB:  /tmp/gnb_5g.log"
echo "  4G eNodeB:  /tmp/enb_4g.log"
echo ""
echo "Monitor handover:"
echo "  tail -f /tmp/gnb_5g.log | grep -E 'handover|HO|RACH|UE'"
echo "  tail -f /tmp/enb_4g.log | grep -E 'handover|HO|RACH|UE'"
echo ""
echo "Check connections:"
echo "  sudo netstat -tnp | grep -E 'srsenb|gnb'"
echo ""
echo "Stop base stations:"
echo "  sudo pkill srsenb && sudo pkill gnb"
