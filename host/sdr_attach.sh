#!/bin/bash
#####################################################################
# SDR USB ATTACHMENT SCRIPT
#
# Automatically detects and attaches USRP B210 devices to running VMs
#####################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║        SDR USB Attachment Script                      ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check if user is in vboxusers group
if ! groups | grep -q vboxusers; then
    echo -e "${RED}❌ ERROR: User not in vboxusers group${NC}"
    echo ""
    echo "You must be in the vboxusers group to access USB devices."
    echo "Run the following commands:"
    echo ""
    echo "  sudo usermod -aG vboxusers $USER"
    echo "  # Then LOG OUT and LOG BACK IN"
    echo ""
    echo "After logging back in, run this script again."
    exit 1
fi

echo -e "${GREEN}✓ User is in vboxusers group${NC}"

# Check if VMs are running
check_vm_running() {
    local vm_name=$1
    if VBoxManage list runningvms | grep -q "$vm_name"; then
        echo -e "${GREEN}✓ $vm_name is running${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $vm_name is not running${NC}"
        return 1
    fi
}

# Get USB devices
get_usb_devices() {
    echo "Scanning for USB devices..."
    VBoxManage list usbhost 2>/dev/null | grep -A 20 "VendorId:.*0x2500" || {
        echo -e "${YELLOW}No Ettus Research devices found via VBoxManage${NC}"
        echo "Trying alternative detection..."
        lsusb -d 2500:0020 2>/dev/null || echo "No USRP B210 devices detected via lsusb"
        return 1
    }
}

# Extract device UUIDs
extract_device_info() {
    local usb_output="$1"
    echo "$usb_output" | grep -E "(UUID|VendorId|ProductId|Product|SerialNumber)" | head -10
}

# Attach device to VM
attach_device() {
    local vm_name=$1
    local device_uuid=$2
    local device_name=$3

    echo "Attaching $device_name to $vm_name..."
    if VBoxManage controlvm "$vm_name" usbattach "$device_uuid" 2>/dev/null; then
        echo -e "${GREEN}✓ Successfully attached $device_name to $vm_name${NC}"
        return 0
    else
        echo -e "${RED}❌ Failed to attach $device_name to $vm_name${NC}"
        return 1
    fi
}

# Main logic
main() {
    local legitimate_vm="legitimate-base-station"
    local false_vm="false-base-station"

    echo "Checking VM status..."
    check_vm_running "$legitimate_vm" || exit 1

    echo ""
    echo "Getting USB device information..."
    local usb_info=$(get_usb_devices)

    if [ -z "$usb_info" ]; then
        echo ""
        echo -e "${RED}❌ No USRP devices found${NC}"
        echo ""
        echo "Troubleshooting:"
        echo "1. Ensure SDR devices are plugged in and powered"
        echo "2. Try different USB ports (preferably USB 3.0)"
        echo "3. Check device permissions: lsusb -v -d 2500:0020"
        echo "4. Try manual attachment through VirtualBox GUI"
        exit 1
    fi

    echo ""
    echo "Found devices:"
    echo "$usb_info"
    echo ""

    # Extract UUIDs (this is a simplified approach - you might need to parse more carefully)
    local uuids=$(echo "$usb_info" | grep "UUID:" | awk '{print $2}')

    if [ -z "$uuids" ]; then
        echo -e "${RED}❌ Could not extract device UUIDs${NC}"
        echo ""
        echo "Try manual attachment:"
        echo "1. Open VirtualBox Manager"
        echo "2. Select the running VM"
        echo "3. Devices → USB → Select USRP B210"
        exit 1
    fi

    echo "Device UUIDs found: $uuids"
    echo ""

    # Attach first device to legitimate VM
    local first_uuid=$(echo "$uuids" | head -1)
    if attach_device "$legitimate_vm" "$first_uuid" "USRP B210 #1"; then
        echo ""
        echo "Testing device in VM..."
        echo "SSH into the VM and run: uhd_find_devices"
        echo ""
        echo "If device works, you can now start the legitimate base station:"
        echo "  sudo switch_network.sh 4g"
        echo "  sudo srsenb /etc/srsran/legitimate/enb_4g.conf"
        echo ""
        echo "Then proceed with false BS setup."
    fi

    # Note about second device
    local second_uuid=$(echo "$uuids" | tail -1)
    if [ "$first_uuid" != "$second_uuid" ]; then
        echo ""
        echo "Second device detected: $second_uuid"
        echo "Start the false BS VM first, then attach this device:"
        echo "  ./START_VMS.sh false"
        echo "  # Wait for VM to boot"
        echo "  VBoxManage controlvm '$false_vm' usbattach '$second_uuid'"
    fi
}

# Alternative manual method
show_manual_method() {
    echo ""
    echo "Alternative: Manual Attachment Method"
    echo "===================================="
    echo ""
    echo "If automatic detection fails:"
    echo ""
    echo "1. Start the VM:"
    echo "   ./START_VMS.sh legitimate"
    echo ""
    echo "2. Get device UUID manually:"
    echo "   VBoxManage list usbhost"
    echo ""
    echo "3. Attach device:"
    echo "   VBoxManage controlvm 'legitimate-base-station' usbattach <UUID>"
    echo ""
    echo "4. Verify in VM:"
    echo "   ./SSH_VM.sh legitimate"
    echo "   uhd_find_devices"
}

# Run main function
main

# Show alternative method
show_manual_method



