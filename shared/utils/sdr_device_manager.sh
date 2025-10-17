#!/bin/bash
#####################################################################
# SDR DEVICE MANAGER UTILITY
#
# Handles SDR device detection, validation, and conflict prevention
# Ensures each VM uses the correct SDR device by serial number
#
# Usage:
#   source /vagrant/shared/utils/sdr_device_manager.sh
#   detect_sdr_devices
#   validate_sdr_assignment "EXPECTED_SERIAL"
#   get_sdr_serial
#####################################################################

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Function to detect all connected SDR devices
detect_sdr_devices() {
    echo -e "${BLUE}Detecting SDR devices...${NC}"

    # Get device information using uhd_find_devices
    if command -v uhd_find_devices >/dev/null 2>&1; then
        device_info=$(uhd_find_devices 2>/dev/null)
        device_count=$(echo "$device_info" | grep -c "serial:")

        if [ "$device_count" -eq 0 ]; then
            echo -e "${YELLOW}No SDR devices detected${NC}"
            return 1
        fi

        echo -e "${GREEN}Found $device_count SDR device(s):${NC}"
        echo "$device_info" | grep "serial:" | while read -r line; do
            serial=$(echo "$line" | awk '{print $2}')
            addr=$(echo "$line" | awk '{print $4}')
            echo "  • Serial: $serial, Address: $addr"
        done

        return 0
    else
        echo -e "${RED}uhd_find_devices command not found${NC}"
        echo -e "${YELLOW}Please ensure UHD drivers are properly installed${NC}"
        return 1
    fi
}

# Function to get the serial number of the first available SDR device
get_sdr_serial() {
    if command -v uhd_find_devices >/dev/null 2>&1; then
        serial=$(uhd_find_devices 2>/dev/null | grep "serial:" | head -1 | awk '{print $2}')
        if [ -n "$serial" ]; then
            echo "$serial"
            return 0
        fi
    fi
    return 1
}

# Function to validate SDR device assignment
validate_sdr_assignment() {
    local expected_serial="$1"
    local vm_name="${2:-$(hostname)}"

    echo -e "${BLUE}Validating SDR device assignment for $vm_name...${NC}"

    if [ -z "$expected_serial" ]; then
        echo -e "${YELLOW}No expected serial number provided${NC}"
        echo -e "${YELLOW}Attempting to detect available device...${NC}"
        detect_sdr_devices
        return 1
    fi

    if command -v uhd_find_devices >/dev/null 2>&1; then
        device_info=$(uhd_find_devices 2>/dev/null)

        if echo "$device_info" | grep -q "serial: $expected_serial"; then
            echo -e "${GREEN}✓ SDR device with serial $expected_serial is properly assigned${NC}"
            return 0
        else
            echo -e "${RED}✗ Expected SDR device (serial: $expected_serial) not found${NC}"
            echo -e "${YELLOW}Available devices:${NC}"
            detect_sdr_devices
            echo ""
            echo -e "${YELLOW}Troubleshooting:${NC}"
            echo "  1. Ensure the correct SDR device is connected to this VM"
            echo "  2. Check VirtualBox USB device assignment"
            echo "  3. Verify the device is not assigned to another VM"
            echo "  4. Try: VBoxManage list usbhost"
            return 1
        fi
    else
        echo -e "${RED}Cannot validate - uhd_find_devices not available${NC}"
        return 1
    fi
}

# Function to list all USB devices (for debugging)
list_usb_devices() {
    echo -e "${BLUE}USB Device Information:${NC}"
    if command -v lsusb >/dev/null 2>&1; then
        echo "lsusb output:"
        lsusb | grep -i ettus || echo "  No Ettus Research devices found"
    else
        echo "lsusb command not available"
    fi

    echo ""
    echo "VirtualBox USB devices:"
    if command -v VBoxManage >/dev/null 2>&1; then
        VBoxManage list usbhost 2>/dev/null | grep -A2 -B2 -i "Ettus\|USRP" || echo "  No Ettus Research devices in VirtualBox USB host list"
    else
        echo "VBoxManage command not available"
    fi
}

# Function to setup SDR device for specific VM
setup_sdr_device() {
    local vm_type="$1"
    local expected_serial="$2"

    case "$vm_type" in
        "legitimate")
            echo "Setting up SDR Device #1 for Legitimate Base Station..."
            ;;
        "legitimate2")
            echo "Setting up SDR Device #2 for Legitimate2 Base Station (Handover)..."
            ;;
        "false")
            echo "Setting up SDR Device #3 for False Base Station..."
            ;;
        *)
            echo "Unknown VM type: $vm_type"
            return 1
            ;;
    esac

    # Detect devices
    if ! detect_sdr_devices; then
        echo ""
        echo "No SDR devices detected. Please:"
        echo "  1. Connect the appropriate SDR device to your host"
        echo "  2. Assign it to this VM via VirtualBox USB settings"
        echo "  3. Run this script again"
        return 1
    fi

    # Validate assignment if expected serial provided
    if [ -n "$expected_serial" ]; then
        if ! validate_sdr_assignment "$expected_serial" "$vm_type"; then
            return 1
        fi
    fi

    echo ""
    echo "SDR device setup completed successfully!"
    return 0
}

# Function to check for device conflicts
check_device_conflicts() {
    echo -e "${BLUE}Checking for SDR device conflicts...${NC}"

    if command -v uhd_find_devices >/dev/null 2>&1; then
        device_count=$(uhd_find_devices 2>/dev/null | grep -c "serial:")

        if [ "$device_count" -gt 1 ]; then
            echo -e "${RED}⚠️  WARNING: Multiple SDR devices detected!${NC}"
            echo ""
            echo "This may indicate device conflicts between VMs."
            echo "Each VM should have only ONE SDR device assigned."
            echo ""
            echo "Detected devices:"
            uhd_find_devices 2>/dev/null | grep "serial:" | while read -r line; do
                serial=$(echo "$line" | awk '{print $2}')
                echo "  • Serial: $serial"
            done
            echo ""
            echo "Recommendations:"
            echo "  1. Ensure each VM has only its assigned SDR device"
            echo "  2. Check VirtualBox USB device assignments"
            echo "  3. Stop other VMs before starting this one"
            return 1
        elif [ "$device_count" -eq 1 ]; then
            echo -e "${GREEN}✓ Single SDR device detected - no conflicts${NC}"
            return 0
        else
            echo -e "${YELLOW}No SDR devices detected${NC}"
            return 1
        fi
    else
        echo -e "${RED}Cannot check conflicts - uhd_find_devices not available${NC}"
        return 1
    fi
}
