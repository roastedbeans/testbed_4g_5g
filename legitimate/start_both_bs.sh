#!/bin/bash

#####################################################################
# Start Both Base Stations with S1 Verification
#
# Ensures both BSs are registered with MME before handover attempts
#####################################################################

set -e

echo "═══════════════════════════════════════════════════════"
echo "  Starting Legitimate Base Stations for Handover"
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
sleep 2

# Check if MME is running
echo -e "${YELLOW}Checking MME status...${NC}"
if sudo systemctl is-active --quiet open5gs-mmed; then
    echo -e "${GREEN}✓ MME is running${NC}"
else
    echo -e "${RED}✗ MME is not running!${NC}"
    echo "Starting MME..."
    sudo systemctl start open5gs-mmed
    sleep 2
fi

# Start legitimate BS (PCI=1, EARFCN=3600)
echo ""
echo -e "${YELLOW}Starting Legitimate BS (PCI=1)...${NC}"
sudo srsenb /etc/srsran/legitimate/enb.conf > /tmp/enb_legitimate.log 2>&1 &
LEGITIMATE_PID=$!

# Wait for S1 Setup
echo "Waiting for S1 Setup..."
for i in {1..10}; do
    if grep -q "S1.*Setup.*Complete\|S1 Setup Response" /tmp/enb_legitimate.log 2>/dev/null; then
        echo -e "${GREEN}✓ Legitimate BS registered with MME (enb_id=0x19B)${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# Verify it's still running
if ! ps -p $LEGITIMATE_PID > /dev/null; then
    echo -e "${RED}✗ Legitimate BS failed to start!${NC}"
    echo "Check logs: tail -f /tmp/enb_legitimate.log"
    exit 1
fi

# Start legitimate2 BS (PCI=2, EARFCN=3650)
echo ""
echo -e "${YELLOW}Starting Legitimate2 BS (PCI=2)...${NC}"
sudo srsenb /etc/srsran/legitimate2/enb.conf > /tmp/enb_legitimate2.log 2>&1 &
LEGITIMATE2_PID=$!

# Wait for S1 Setup
echo "Waiting for S1 Setup..."
for i in {1..10}; do
    if grep -q "S1.*Setup.*Complete\|S1 Setup Response" /tmp/enb_legitimate2.log 2>/dev/null; then
        echo -e "${GREEN}✓ Legitimate2 BS registered with MME (enb_id=0x19C)${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
echo ""

# Verify it's still running
if ! ps -p $LEGITIMATE2_PID > /dev/null; then
    echo -e "${RED}✗ Legitimate2 BS failed to start!${NC}"
    echo "Check logs: tail -f /tmp/enb_legitimate2.log"
    exit 1
fi

# Final status
echo ""
echo "═══════════════════════════════════════════════════════"
echo -e "${GREEN}✓ Both Base Stations Running${NC}"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Process IDs:"
echo "  Legitimate  (PCI=1, 0x19B): $LEGITIMATE_PID"
echo "  Legitimate2 (PCI=2, 0x19C): $LEGITIMATE2_PID"
echo ""
echo "Log files:"
echo "  Legitimate:  /tmp/enb_legitimate.log"
echo "  Legitimate2: /tmp/enb_legitimate2.log"
echo ""
echo "Monitor handover:"
echo "  tail -f /tmp/enb_legitimate.log | grep -E 'handover|HO|RACH'"
echo "  tail -f /tmp/enb_legitimate2.log | grep -E 'handover|HO|RACH'"
echo ""
echo "Check S1 connections:"
echo "  sudo netstat -tnp | grep srsenb"
echo ""
