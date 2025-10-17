#!/bin/bash
#####################################################################
# SDR SETUP VALIDATION SCRIPT
#
# Validates SDR device assignments and configurations for each VM
# Ensures no conflicts between multiple VMs using SDR devices
#
# Usage: ./validate_sdr_setup.sh [vm_type]
#   vm_type: legitimate, legitimate2, false (optional)
#####################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Source SDR device manager
if [ -f "$SCRIPT_DIR/sdr_device_manager.sh" ]; then
    source "$SCRIPT_DIR/sdr_device_manager.sh"
else
    echo -e "${RED}Error: sdr_device_manager.sh not found${NC}"
    exit 1
fi

# Function to validate VM-specific SDR setup
validate_vm_sdr() {
    local vm_type="$1"
    local vm_dir="$PROJECT_ROOT/$vm_type"
    local config_file="$vm_dir/.sdr_config"

    echo -e "${BLUE}Validating SDR setup for $vm_type...${NC}"
    echo "========================================"

    # Check if VM directory exists
    if [ ! -d "$vm_dir" ]; then
        echo -e "${RED}✗ VM directory not found: $vm_dir${NC}"
        return 1
    fi

    # Check SDR config file
    if [ ! -f "$config_file" ]; then
        echo -e "${YELLOW}⚠ SDR config file not found: $config_file${NC}"
        echo -e "${YELLOW}  Run 'source $vm_dir/.sdr_config' for setup instructions${NC}"
        return 1
    fi

    # Source config
    source "$config_file"

    # Validate expected serial is set
    if [ -z "$EXPECTED_SDR_SERIAL" ]; then
        echo -e "${YELLOW}⚠ EXPECTED_SDR_SERIAL not configured${NC}"
        echo -e "${YELLOW}  Edit $config_file and set EXPECTED_SDR_SERIAL${NC}"
        return 1
    fi

    echo -e "${GREEN}✓ SDR config file found${NC}"
    echo "  Expected Serial: $EXPECTED_SDR_SERIAL"
    echo "  SDR Type: $SDR_TYPE"
    echo "  VM Role: $VM_ROLE"

    # Check if we're running in the correct VM context
    if [ -f "/vagrant/.sdr_config" ]; then
        echo ""
        echo -e "${BLUE}Runtime validation:${NC}"

        # Source runtime config
        source "/vagrant/.sdr_config"

        # Check device detection
        if lsusb | grep -i "Ettus Research" >/dev/null 2>&1; then
            echo -e "${GREEN}✓ SDR device detected via USB${NC}"

            # Validate serial number
            if command -v validate_sdr_assignment >/dev/null 2>&1; then
                if validate_sdr_assignment "$EXPECTED_SDR_SERIAL" "$vm_type"; then
                    echo -e "${GREEN}✓ SDR serial validation passed${NC}"
                else
                    echo -e "${RED}✗ SDR serial validation failed${NC}"
                    return 1
                fi
            fi
        else
            echo -e "${YELLOW}⚠ No SDR device detected via USB${NC}"
            echo -e "${YELLOW}  Ensure SDR device is connected to this VM${NC}"
            return 1
        fi
    else
        echo ""
        echo -e "${YELLOW}Runtime validation skipped (not running in VM)${NC}"
    fi

    echo ""
    return 0
}

# Function to check for conflicts between VMs
check_vm_conflicts() {
    echo -e "${BLUE}Checking for SDR conflicts between VMs...${NC}"
    echo "==========================================="

    local configs_found=0
    local serials=()

    for vm_type in legitimate legitimate2 false; do
        local config_file="$PROJECT_ROOT/$vm_type/.sdr_config"
        if [ -f "$config_file" ]; then
            configs_found=$((configs_found + 1))
            source "$config_file"
            if [ -n "$EXPECTED_SDR_SERIAL" ]; then
                serials+=("$EXPECTED_SDR_SERIAL")
                echo "  $vm_type: $EXPECTED_SDR_SERIAL"
            fi
        fi
    done

    if [ "$configs_found" -eq 0 ]; then
        echo -e "${YELLOW}⚠ No SDR config files found${NC}"
        return 1
    fi

    # Check for duplicate serials
    local unique_serials=$(printf '%s\n' "${serials[@]}" | sort | uniq)
    local duplicate_count=$(printf '%s\n' "${serials[@]}" | sort | uniq -d | wc -l)

    if [ "$duplicate_count" -gt 0 ]; then
        echo ""
        echo -e "${RED}✗ CONFLICT DETECTED: Duplicate SDR serial numbers!${NC}"
        echo "  Each VM must use a different SDR device."
        echo "  Duplicate serials found:"
        printf '%s\n' "${serials[@]}" | sort | uniq -d | while read -r serial; do
            echo "    • $serial"
        done
        echo ""
        echo "  Fix: Assign different SDR devices to each VM"
        return 1
    else
        echo ""
        echo -e "${GREEN}✓ No serial number conflicts detected${NC}"
        echo "  All VMs have unique SDR device assignments"
        return 0
    fi
}

# Function to show frequency information
show_frequency_info() {
    echo -e "${BLUE}SDR Frequency Configuration:${NC}"
    echo "=============================="

    echo "Frequency separation prevents interference:"
    echo "• legitimate (primary):   3450 MHz (primary), 3550/3650 (secondary)"
    echo "• legitimate2 (handover): 3550 MHz (primary), 3450/3650 (secondary)"
    echo "• false (rogue):         3650 MHz (primary), 3450/3600 (secondary)"
    echo ""
    echo "This allows proper handover testing between legitimate base stations."
}

# Main validation function
main() {
    local vm_type="$1"

    echo -e "${BLUE}SDR Setup Validation Tool${NC}"
    echo "=========================="
    echo ""

    # Show frequency info
    show_frequency_info
    echo ""

    # Check for VM conflicts
    if ! check_vm_conflicts; then
        echo ""
        echo -e "${RED}SDR conflict resolution required before proceeding.${NC}"
    fi
    echo ""

    # Validate specific VM if requested
    if [ -n "$vm_type" ]; then
        case "$vm_type" in
            legitimate|legitimate2|false)
                validate_vm_sdr "$vm_type"
                ;;
            *)
                echo -e "${RED}Invalid VM type: $vm_type${NC}"
                echo "Valid options: legitimate, legitimate2, false"
                exit 1
                ;;
        esac
    else
        # Validate all VMs
        local all_valid=true
        for vm in legitimate legitimate2 false; do
            if ! validate_vm_sdr "$vm"; then
                all_valid=false
            fi
            echo ""
        done

        if $all_valid; then
            echo -e "${GREEN}✓ All SDR configurations validated successfully${NC}"
        else
            echo -e "${YELLOW}⚠ Some SDR configurations need attention${NC}"
            exit 1
        fi
    fi
}

# Show usage if requested
if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Usage: $0 [vm_type]"
    echo ""
    echo "Arguments:"
    echo "  vm_type    Validate specific VM (legitimate, legitimate2, false)"
    echo "  --help     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                    # Validate all VMs"
    echo "  $0 legitimate        # Validate legitimate VM only"
    echo "  $0 --help            # Show this help"
    exit 0
fi

# Run main validation
main "$@"
