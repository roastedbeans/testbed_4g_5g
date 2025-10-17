#!/bin/bash
# False Base Station Attack Infrastructure - Validation Script
# Validates all components are installed and configured correctly

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}False Base Station Attack Infrastructure - Validation${NC}"
echo ""

# Check if VMs are running
echo "=== Checking VM Status ==="
if VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant status | grep -q "running"; then
    echo -e "${GREEN}✅ Legitimate BS VM is running${NC}"
    LEGIT_RUNNING=true
else
    echo -e "${YELLOW}⚠️  Legitimate BS VM is not running${NC}"
    LEGIT_RUNNING=false
fi

if VAGRANT_VAGRANTFILE=false/Vagrantfile vagrant status | grep -q "running"; then
    echo -e "${GREEN}✅ False BS VM is running${NC}"
    FALSE_RUNNING=true
else
    echo -e "${YELLOW}⚠️  False BS VM is not running${NC}"
    FALSE_RUNNING=false
fi

echo ""

# Validate legitimate BS if running
if [ "$LEGIT_RUNNING" = true ]; then
    echo "=== Validating Legitimate BS ==="

    echo "Checking SDR drivers..."
    if VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "uhd_find_devices --help > /dev/null" 2>/dev/null; then
        echo -e "${GREEN}✅ UHD SDR drivers installed${NC}"
    else
        echo -e "${RED}❌ UHD SDR drivers not found${NC}"
    fi

    echo "Checking Open5GS services..."
    if VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "systemctl is-active open5gs-mmed" 2>/dev/null; then
        echo -e "${GREEN}✅ Open5GS MME service running${NC}"
    else
        echo -e "${RED}❌ Open5GS MME service not running${NC}"
    fi

    if VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "systemctl is-active open5gs-amfd" 2>/dev/null; then
        echo -e "${GREEN}✅ Open5GS AMF service running${NC}"
    else
        echo -e "${RED}❌ Open5GS AMF service not running${NC}"
    fi

    echo "Checking Open5GS WebUI..."
    if VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "systemctl is-active open5gs-webui" 2>/dev/null; then
        echo -e "${GREEN}✅ Open5GS WebUI service running${NC}"
        if VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "curl -I http://localhost:9999 2>/dev/null | grep -q '200'" 2>/dev/null; then
            echo -e "${GREEN}✅ Open5GS WebUI accessible${NC}"
        else
            echo -e "${YELLOW}⚠️  Open5GS WebUI service running but not accessible${NC}"
        fi
    else
        echo -e "${RED}❌ Open5GS WebUI service not running${NC}"
    fi

    echo "Checking srsRAN..."
    if VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "which srsenb > /dev/null" 2>/dev/null; then
        echo -e "${GREEN}✅ srsRAN 4G (srsenb) installed${NC}"
    else
        echo -e "${RED}❌ srsRAN 4G not installed${NC}"
    fi

    if VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "which gnb > /dev/null" 2>/dev/null; then
        echo -e "${GREEN}✅ srsRAN 5G (gnb) installed${NC}"
    else
        echo -e "${YELLOW}⚠️  srsRAN 5G not installed (optional)${NC}"
    fi

    echo "Checking configuration files..."
    if VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "ls /etc/srsran/legitimate/ 2>/dev/null | wc -l" 2>/dev/null; then
        COUNT=$(VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "ls /etc/srsran/legitimate/ 2>/dev/null | wc -l" 2>/dev/null)
        echo -e "${GREEN}✅ srsRAN configuration files deployed ($COUNT files)${NC}"
    else
        echo -e "${RED}❌ srsRAN configuration files not deployed${NC}"
    fi

    echo "Checking Open5GS configuration..."
    if VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "ls /etc/open5gs/mme.yaml /etc/open5gs/amf.yaml 2>/dev/null" 2>/dev/null; then
        echo -e "${GREEN}✅ Open5GS configuration files deployed${NC}"
    else
        echo -e "${RED}❌ Open5GS configuration files not deployed${NC}"
    fi

    echo ""
fi

# Validate false BS if running
if [ "$FALSE_RUNNING" = true ]; then
    echo "=== Validating False BS ==="

    echo "Checking SDR drivers..."
    if VAGRANT_VAGRANTFILE=false/Vagrantfile vagrant ssh -c "uhd_find_devices --help > /dev/null" 2>/dev/null; then
        echo -e "${GREEN}✅ UHD SDR drivers installed${NC}"
    else
        echo -e "${RED}❌ UHD SDR drivers not found${NC}"
    fi

    echo "Checking srsRAN..."
    if VAGRANT_VAGRANTFILE=false/Vagrantfile vagrant ssh -c "which srsenb > /dev/null" 2>/dev/null; then
        echo -e "${GREEN}✅ srsRAN 4G (srsenb) installed${NC}"
    else
        echo -e "${RED}❌ srsRAN 4G not installed${NC}"
    fi

    echo "Checking attack profiles..."
    if VAGRANT_VAGRANTFILE=false/Vagrantfile vagrant ssh -c "ls /opt/attack_profiles/ 2>/dev/null | wc -l" 2>/dev/null; then
        COUNT=$(VAGRANT_VAGRANTFILE=false/Vagrantfile vagrant ssh -c "ls /opt/attack_profiles/ 2>/dev/null | wc -l" 2>/dev/null)
        echo -e "${GREEN}✅ Attack profiles deployed ($COUNT files)${NC}"
    else
        echo -e "${RED}❌ Attack profiles not deployed${NC}"
    fi

    echo "Checking rogue configuration files..."
    if VAGRANT_VAGRANTFILE=false/Vagrantfile vagrant ssh -c "ls /etc/srsran/false/ 2>/dev/null | wc -l" 2>/dev/null; then
        COUNT=$(VAGRANT_VAGRANTFILE=false/Vagrantfile vagrant ssh -c "ls /etc/srsran/false/ 2>/dev/null | wc -l" 2>/dev/null)
        echo -e "${GREEN}✅ Rogue srsRAN configuration files deployed ($COUNT files)${NC}"
    else
        echo -e "${RED}❌ Rogue srsRAN configuration files not deployed${NC}"
    fi

    echo ""
fi

echo "=== Summary ==="
echo ""

if [ "$LEGIT_RUNNING" = true ]; then
    echo -e "${GREEN}✅ Legitimate BS VM: Validated${NC}"
else
    echo -e "${YELLOW}⚠️  Legitimate BS VM: Not running (start with: ./start.sh legitimate)${NC}"
fi

if [ "$FALSE_RUNNING" = true ]; then
    echo -e "${GREEN}✅ False BS VM: Validated${NC}"
else
    echo -e "${YELLOW}⚠️  False BS VM: Not running (start with: ./start.sh false)${NC}"
fi

echo ""
echo "=== Quick Start Commands ==="
echo ""
echo "Start legitimate BS:  ./start.sh legitimate"
echo "Start false BS:       ./start.sh false"
echo "Start both:           ./start.sh both"
echo "SSH to legitimate:    ./ssh.sh legitimate"
echo "SSH to false:         ./ssh.sh false"
echo "Stop all:             ./stop.sh both"
echo ""

if [ "$LEGIT_RUNNING" = true ]; then
    VM_IP=$(VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant ssh -c "ip addr show | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print \$2}' | cut -d'/' -f1" 2>/dev/null)
    if [ -n "$VM_IP" ]; then
        echo "Open5GS WebUI (legitimate BS): http://$VM_IP:9999"
        echo "Default credentials: admin / 1423"
    fi
fi

echo ""
echo -e "${BLUE}Validation completed!${NC}"
