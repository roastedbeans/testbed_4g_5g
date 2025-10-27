#!/bin/bash
#####################################################################
# SDR Device Manager
#
# Unified SDR device management for all VMs
# Handles device checking and VirtualBox USB attachment
#
# Usage: ./sdr_manager.sh [command] [vm_name]
#
# Commands:
#   check        - Check available SDR devices on host
#   attach       - Attach SDR device(s) to specified VM
#   detach       - Detach SDR device from specified VM
#   status       - Show current USB device assignments
#   auto         - Automatically attach correct devices to all running VMs
#
# VMs: legitimate (C5XA7X9 + P44SEGH), false (VRFKZRP), legitimate_5g (C5XA7X9)
#####################################################################

set -e

# Color codes 
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# SDR Device UUIDs (update these if your devices change)
declare -A SDR_UUIDS=(
    ["C5XA7X9"]="8725cd1b-99dd-4194-8ffc-bea4b0e3ba0a"   # SDR #1 (legitimate & legitimate_5g) - actually reports as C5XA7X9
    ["P44SEGH"]="73fec958-367f-4f18-b94e-5a585d561ac4"   # SDR #2 (now with legitimate)
    ["VRFKZRP"]="0094e7c0-a8c1-44d4-a05f-573be7da1b84"   # SDR #3 (false)
)

# VM to SDR mapping (now supports multiple devices per VM)
declare -A VM_SDR_MAP=(
    ["legitimate"]="C5XA7X9 P44SEGH"  # Both SDR #1 and SDR #2
    ["false"]="VRFKZRP"  # SDR #3
    ["legitimate_5g"]="C5XA7X9"  # Shares SDR #1 with legitimate
)

# VM display names
declare -A VM_NAMES=(
    ["legitimate"]="legitimate-base-station"
    ["false"]="false-base-station"
    ["legitimate_5g"]="legitimate-5g-base-station"
)

# Function to check available SDR devices
check_devices() {
    echo -e "${BLUE}Checking SDR Devices on Host:${NC}"
    echo "================================"

    if ! command -v VBoxManage >/dev/null 2>&1; then
        echo -e "${RED}VBoxManage not found. Please install VirtualBox.${NC}"
        exit 1
    fi

    echo "VirtualBox USB Host Devices:"
    VBoxManage list usbhost | grep -A 2 -B 2 -i "Ettus\|USRP" || echo "  No Ettus Research devices found"

    echo ""
    echo "UHD Device Detection:"
    if command -v uhd_find_devices >/dev/null 2>&1; then
        uhd_find_devices 2>/dev/null || echo "  No UHD devices detected"
    else
        echo "  UHD not available (run inside VM)"
    fi
}

# Function to attach SDR to VM
attach_device() {
    local vm_short="$1"
    local sdr_serials="${VM_SDR_MAP[$vm_short]}"
    local vm_full="${VM_NAMES[$vm_short]}"

    if [ -z "$sdr_serials" ]; then
        echo -e "${YELLOW}No SDR devices assigned to $vm_short${NC}"
        return 0
    fi

    echo -e "${BLUE}Attaching SDR devices to $vm_full...${NC}"

    # Check if VM is running
    if ! VBoxManage list runningvms | grep -q "$vm_full"; then
        echo -e "${YELLOW}Warning: VM $vm_full is not running${NC}"
        echo -e "${YELLOW}Start it first: vagrant up $vm_short${NC}"
        return 1
    fi

    local attached_count=0
    local total_count=0

    # Process each SDR serial assigned to this VM
    for sdr_serial in $sdr_serials; do
        total_count=$((total_count + 1))
        local uuid="${SDR_UUIDS[$sdr_serial]}"

        if [ -z "$uuid" ]; then
            echo -e "${RED}Error: No UUID found for SDR $sdr_serial${NC}"
            continue
        fi

        echo -e "${BLUE}  Attaching SDR $sdr_serial...${NC}"

        # Check if device is already attached
        if VBoxManage showvminfo "$vm_full" | grep -q "$uuid"; then
            echo -e "${GREEN}  ✓ SDR $sdr_serial already attached${NC}"
            attached_count=$((attached_count + 1))
            continue
        fi

        # Attach the device
        if VBoxManage controlvm "$vm_full" usbattach "$uuid" 2>/dev/null; then
            echo -e "${GREEN}  ✓ Successfully attached SDR $sdr_serial${NC}"
            attached_count=$((attached_count + 1))

            # Wait a moment for device to initialize
            sleep 1
        else
            echo -e "${RED}  ✗ Failed to attach SDR $sdr_serial${NC}"
            echo -e "${YELLOW}  Try using VirtualBox GUI: Devices → USB → Select device${NC}"
        fi
    done

    # Final verification
    sleep 1
    local final_attached=$(VBoxManage showvminfo "$vm_full" 2>/dev/null | grep -c "UUID:" || echo "0")

    echo -e "${GREEN}✓ Attached $attached_count/$total_count SDR device(s) to $vm_full${NC}"

    if [ "$attached_count" -gt 0 ]; then
        return 0
    else
        return 1
    fi
}

# Function to detach SDR from VM
detach_device() {
    local vm_short="$1"
    local vm_full="${VM_NAMES[$vm_short]}"

    echo -e "${BLUE}Detaching all SDR devices from $vm_full...${NC}"

    # Get attached USB devices
    attached_devices=$(VBoxManage showvminfo "$vm_full" | grep "UUID:" | awk '{print $2}')

    if [ -z "$attached_devices" ]; then
        echo -e "${YELLOW}No USB devices attached to $vm_full${NC}"
        return 0
    fi

    # Detach SDR devices
    for uuid in $attached_devices; do
        if [[ " ${SDR_UUIDS[*]} " =~ " $uuid " ]]; then
            if VBoxManage controlvm "$vm_full" usbdetach "$uuid" 2>/dev/null; then
                echo -e "${GREEN}✓ Detached SDR device $uuid from $vm_full${NC}"
            else
                echo -e "${YELLOW}⚠ Failed to detach device $uuid${NC}"
            fi
        fi
    done
}

# Function to show status
show_status() {
    echo -e "${BLUE}Current SDR Device Status:${NC}"
    echo "============================"

    # Check running VMs
    echo "Running VMs:"
    running_vms=$(VBoxManage list runningvms 2>/dev/null | awk -F'"' '{print $2}' || echo "")
    if [ -z "$running_vms" ]; then
        echo "  No VMs running"
    else
        echo "$running_vms" | while read vm; do
            echo "  • $vm"
        done
    fi

    echo ""
    echo "SDR Device Assignments:"

    # Check each VM's USB devices
    for vm_short in legitimate false legitimate_5g; do
        vm_full="${VM_NAMES[$vm_short]}"
        expected_sdrs="${VM_SDR_MAP[$vm_short]}"

        echo ""
        echo "$vm_short ($vm_full):"
        if [ -n "$expected_sdrs" ]; then
            echo "  Expected SDRs: $expected_sdrs"
        else
            echo "  Expected SDRs: None"
        fi

        if VBoxManage list runningvms 2>/dev/null | grep -q "$vm_full"; then
            # Extract only USB device UUIDs from the "Currently attached USB devices" section
            attached_devices=$(VBoxManage showvminfo "$vm_full" 2>/dev/null | sed -n '/Currently attached USB devices:/,/^Bandwidth groups:/p' | grep "^UUID:" | awk '{print $2}' || echo "")

            if [ -n "$attached_devices" ]; then
                echo "  Attached devices:"
                for uuid in $attached_devices; do
                    # Find which SDR this UUID corresponds to
                    sdr_name="Unknown"
                    for sdr_serial in "${!SDR_UUIDS[@]}"; do
                        if [ "${SDR_UUIDS[$sdr_serial]}" = "$uuid" ]; then
                            sdr_name="$sdr_serial"
                            break
                        fi
                    done
                    echo "    • $sdr_name ($uuid)"
                done
            else
                echo "  Attached devices: None"
            fi
        else
            echo "  Status: VM not running"
        fi
    done
}

# Function to auto-attach devices to running VMs
auto_attach() {
    echo -e "${BLUE}Auto-attaching SDR devices to running VMs...${NC}"
    echo "==============================================="

    running_vms=$(VBoxManage list runningvms 2>/dev/null | awk -F'"' '{print $2}' || echo "")

    if [ -z "$running_vms" ]; then
        echo -e "${YELLOW}No VMs are currently running${NC}"
        return 0
    fi

    echo "Found running VMs:"
    echo "$running_vms" | while read vm_full; do
        echo "  • $vm_full"
    done

    echo ""
    attached_count=0

    # Map full VM names back to short names
    for vm_full in $running_vms; do
        vm_short=""
        for short in "${!VM_NAMES[@]}"; do
            if [ "${VM_NAMES[$short]}" = "$vm_full" ]; then
                vm_short="$short"
                break
            fi
        done

        if [ -n "$vm_short" ]; then
            # Check if this VM has any SDR devices assigned
            local vm_sdrs="${VM_SDR_MAP[$vm_short]}"
            if [ -n "$vm_sdrs" ]; then
                echo "Processing $vm_short ($vm_full)..."
                if attach_device "$vm_short"; then
                    attached_count=$((attached_count + 1))
                fi
                echo ""
            else
                echo -e "${YELLOW}Skipping $vm_short ($vm_full) - no SDR devices assigned${NC}"
                echo ""
            fi
        else
            echo -e "${YELLOW}Skipping unknown VM: $vm_full${NC}"
        fi
    done

    echo -e "${GREEN}Auto-attach complete: $attached_count device(s) processed${NC}"
}

# Main function
main() {
    local command="$1"
    local vm_name="$2"

    case "$command" in
        "check")
            check_devices
            ;;
        "attach")
            if [ -z "$vm_name" ]; then
                echo -e "${RED}Error: Please specify VM name${NC}"
                echo "Usage: $0 attach [legitimate|false|legitimate_5g]"
                exit 1
            fi
            attach_device "$vm_name"
            ;;
        "detach")
            if [ -z "$vm_name" ]; then
                echo -e "${RED}Error: Please specify VM name${NC}"
                echo "Usage: $0 detach [legitimate|false|legitimate_5g]"
                exit 1
            fi
            detach_device "$vm_name"
            ;;
        "status")
            show_status
            ;;
        "auto")
            auto_attach
            ;;
        "help"|"-h"|"--help")
            echo "SDR Device Manager"
            echo "=================="
            echo ""
            echo "Usage: $0 <command> [vm_name]"
            echo ""
            echo "Commands:"
            echo "  check        - Check available SDR devices on host"
            echo "  attach <vm>  - Attach SDR device to specified VM"
            echo "  detach <vm>  - Detach SDR device from specified VM"
            echo "  status       - Show current USB device assignments"
            echo "  auto         - Auto-attach correct devices to running VMs"
            echo "  help         - Show this help message"
            echo ""
            echo "VMs:"
            echo "  legitimate   - C5XA7X9 + P44SEGH (both SDRs)"
            echo "  false        - VRFKZRP (SDR #3)"
            echo "  legitimate_5g - C5XA7X9 (shares with legitimate)"
            echo ""
            echo "Examples:"
            echo "  $0 check"
            echo "  $0 attach legitimate    # Attach both SDRs"
            echo "  $0 attach false         # Attach single SDR"
            echo "  $0 status"
            echo "  $0 auto"
            ;;
        *)
            echo -e "${RED}Error: Unknown command '$command'${NC}"
            echo "Run '$0 help' for usage information"
            exit 1
            ;;
    esac
}

# Run main function with arguments
main "$@"
