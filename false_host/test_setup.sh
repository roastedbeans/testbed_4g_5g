#!/bin/bash
#####################################################################
# FALSE BASE STATION HOST TEST SCRIPT
#
# Tests the false base station setup on host system
# Verifies installation and basic functionality
#####################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  False BS Host Setup Test${NC}"
echo -e "${BLUE}======================================${NC}"
echo ""

#####################################################################
# Test 1: Check if required commands are available
#####################################################################
echo -e "${BLUE}Testing required commands...${NC}"

commands=("uhd_find_devices" "uhd_usrp_probe" "srsenb")
missing_commands=()

for cmd in "${commands[@]}"; do
    if command -v "$cmd" >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} $cmd found"
    else
        echo -e "${RED}✗${NC} $cmd not found"
        missing_commands+=("$cmd")
    fi
done

if [ ${#missing_commands[@]} -gt 0 ]; then
    echo -e "${YELLOW}Warning: Some commands are missing. Run setup_host.sh first.${NC}"
fi

echo ""

#####################################################################
# Test 2: Check configuration files
#####################################################################
echo -e "${BLUE}Testing configuration files...${NC}"

config_checks=(
    "./configs/attack_profiles/enb.conf:Main eNodeB config"
    "./configs/attack_profiles/rr.conf:Radio resources config"
    "./configs/attack_profiles/rb.conf:Radio bearer config"
    "./configs/attack_profiles/sib.conf:System info config"
    "./configs/attack_profiles/imsi_catcher.conf:IMSI catcher profile"
    "./scripts/start_false_bs.sh:Start script"
)

for check in "${config_checks[@]}"; do
    file=$(echo "$check" | cut -d: -f1)
    description=$(echo "$check" | cut -d: -f2)

    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $description found"
    else
        echo -e "${RED}✗${NC} $description missing: $file"
    fi
done

echo ""

#####################################################################
# Test 3: Check SDR device detection
#####################################################################
echo -e "${BLUE}Testing SDR device detection...${NC}"

if lsusb | grep -i "Ettus Research" >/dev/null 2>&1; then
    echo -e "${GREEN}✓${NC} LibreSDR device detected via USB"

    # Test UHD device detection
    if uhd_find_devices >/dev/null 2>&1; then
        echo -e "${GREEN}✓${NC} UHD device detection working"

        # Count devices
        device_count=$(uhd_find_devices 2>/dev/null | grep -c "serial:")
        echo -e "${BLUE}ℹ${NC} $device_count UHD device(s) detected"

        # Check expected serial if configured
        if [ -f "./.sdr_config" ]; then
            source "./.sdr_config"
            if [ -n "$EXPECTED_SDR_SERIAL" ]; then
                if uhd_find_devices 2>/dev/null | grep -q "serial: $EXPECTED_SDR_SERIAL"; then
                    echo -e "${GREEN}✓${NC} Expected SDR serial $EXPECTED_SDR_SERIAL found"
                else
                    echo -e "${YELLOW}⚠${NC} Expected SDR serial $EXPECTED_SDR_SERIAL not found"
                fi
            fi
        fi
    else
        echo -e "${RED}✗${NC} UHD device detection failed"
    fi
else
    echo -e "${YELLOW}⚠${NC} No LibreSDR device detected via USB"
    echo -e "${YELLOW}   Make sure SDR #3 is connected${NC}"
fi

echo ""

#####################################################################
# Test 4: Check permissions
#####################################################################
echo -e "${BLUE}Testing permissions...${NC}"

# Check if user is in plugdev group
if groups | grep -q plugdev; then
    echo -e "${GREEN}✓${NC} User in plugdev group"
else
    echo -e "${RED}✗${NC} User not in plugdev group"
    echo -e "${YELLOW}   Run: sudo usermod -a -G plugdev \$USER${NC}"
fi

# Check udev rules
if [ -f "/etc/udev/rules.d/10-usrp.rules" ]; then
    echo -e "${GREEN}✓${NC} USRP udev rules installed"
else
    echo -e "${RED}✗${NC} USRP udev rules missing"
fi

echo ""

#####################################################################
# Summary
#####################################################################
echo -e "${BLUE}======================================${NC}"
echo -e "${BLUE}  Test Summary${NC}"
echo -e "${BLUE}======================================${NC}"

if [ ${#missing_commands[@]} -eq 0 ] && lsusb | grep -q "Ettus Research"; then
    echo -e "${GREEN}✓ Setup appears complete and ready!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Run: attack_config.sh set imsi_catcher"
    echo "  2. Run: start_false_bs.sh"
else
    echo -e "${YELLOW}⚠ Setup incomplete. Run ./setup_host.sh first.${NC}"
fi

echo ""
echo -e "${YELLOW}Remember: Start legitimate BS before false BS!${NC}"
