#!/bin/bash

################################################################################
# LibreSDR B210/B220 AD9361 Setup Script for Linux
# This script builds UHD 4.8 from source and configures LibreSDR devices
# Based on: https://gainsec.com/2025/01/23/setting-up-and-configuring-libresdr-b210-b220-ad9361-on-windows-and-linux/
# Uses UHD 4.8 from: https://github.com/EttusResearch/uhd/tree/UHD-4.8
################################################################################

set -e  # Exit on error

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to print colored messages
print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_info() {
    echo -e "${YELLOW}[INFO]${NC} $1"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
   print_error "This script should not be run as root. Please run as a normal user."
   exit 1
fi

# Check for sudo privileges
if ! sudo -v; then
    print_error "This script requires sudo privileges"
    exit 1
fi

print_info "Starting LibreSDR B210/B220 Setup..."

################################################################################
# Step 1: Install UHD build dependencies
################################################################################
print_info "Removing existing UHD packages to avoid conflicts..."
sudo apt-get remove -y libuhd-dev uhd-host libuhd4.8.0 2>/dev/null || true
sudo apt-get autoremove -y

print_info "Installing UHD build dependencies..."
sudo apt-get update
sudo apt-get install -y cmake make gcc g++ pkg-config git \
    libboost-all-dev libfftw3-dev libmbedtls-dev \
    python3-dev python3-mako python3-numpy python3-requests python3-setuptools \
    libusb-1.0-0-dev libpoco-dev libncurses5-dev libtecla1 libtecla-dev

print_success "UHD build dependencies installed successfully"

################################################################################
# Step 2: Build and install UHD 4.8 from source
################################################################################
print_info "Building UHD 4.8 from source..."
TEMP_DIR=$(mktemp -d)
cd "$TEMP_DIR"

# Clone UHD 4.8 branch
print_info "Cloning UHD 4.8 branch..."
if ! git clone --branch UHD-4.8 --depth 1 https://github.com/EttusResearch/uhd.git; then
    print_error "Failed to clone UHD repository"
    print_info "Trying alternative installation method..."
    # Fallback: install UHD from Ubuntu repository
    sudo apt-get update
    sudo apt-get install -y libuhd-dev uhd-host
    print_success "UHD installed from Ubuntu repository"
    exit 0
fi

if [ ! -d "uhd" ]; then
    print_error "UHD directory not found after cloning"
    exit 1
fi

cd uhd

# Check current branch and directory contents
print_info "Checking UHD repository structure..."
git branch --show-current
ls -la

# Initialize submodules if needed
git submodule update --init --recursive

# UHD 4.8 has CMakeLists.txt in the host directory
if [ ! -f "host/CMakeLists.txt" ]; then
    print_error "CMakeLists.txt not found in UHD host directory"
    print_info "Contents of UHD directory:"
    ls -la
    print_info "Contents of host directory:"
    ls -la host/
    print_error "UHD repository structure may have changed. Please check the UHD-4.8 branch."
    exit 1
fi

# Create build directory in host
cd host
mkdir build && cd build

# Configure with CMake (point to parent directory)
cmake -DCMAKE_INSTALL_PREFIX=/usr -DENABLE_PYTHON_API=ON -DENABLE_EXAMPLES=ON -DENABLE_UTILS=ON ..

# Build and install
make -j$(nproc)
sudo make install
sudo ldconfig

print_success "UHD 4.8 built and installed successfully"

################################################################################
# Step 3: Download UHD images
################################################################################
print_info "Downloading UHD images..."
if [ -f /usr/lib/uhd/utils/uhd_images_downloader.py ]; then
    sudo python3 /usr/lib/uhd/utils/uhd_images_downloader.py
    print_success "UHD images downloaded successfully"
else
    print_error "uhd_images_downloader.py not found at expected location"
    exit 1
fi

################################################################################
# Step 4: Clone LibreSDR USRP repository for custom firmware
################################################################################
print_info "Cloning LibreSDR USRP repository for custom FPGA image..."
LIBRESDR_DIR=$(mktemp -d)
cd "$LIBRESDR_DIR"

if ! git clone https://github.com/alphafox02/LibreSDR_USRP; then
    print_error "Failed to clone LibreSDR USRP repository"
    print_info "Continuing without custom FPGA image..."
    cd /
    rm -rf "$LIBRESDR_DIR"
    exit 0
fi

if [ ! -d "LibreSDR_USRP" ]; then
    print_error "LibreSDR_USRP directory not found after cloning"
    exit 1
fi

cd LibreSDR_USRP

print_success "Repository cloned successfully"

################################################################################
# Step 4: Copy custom FPGA image to UHD images directory
################################################################################
print_info "Copying custom FPGA image to UHD images directory..."
if [ -f usrp_b210_fpga.bin ]; then
    # Find the UHD images directory (it might be versioned like /usr/share/uhd/4.9.0/images)
    UHD_IMAGES_DIR=$(find /usr/share/uhd -type d -name "images" | head -1)
    if [ -z "$UHD_IMAGES_DIR" ]; then
        # Try versioned directory directly
        UHD_VERSION_DIR=$(ls /usr/share/uhd/ | grep -E '^[0-9]+\.[0-9]+\.[0-9]+' | head -1)
        if [ -n "$UHD_VERSION_DIR" ]; then
            UHD_IMAGES_DIR="/usr/share/uhd/$UHD_VERSION_DIR/images"
        else
            print_error "UHD images directory not found"
            exit 1
        fi
    fi
    sudo cp usrp_b210_fpga.bin "$UHD_IMAGES_DIR/"
    print_success "Custom FPGA image copied to $UHD_IMAGES_DIR/"
else
    print_error "usrp_b210_fpga.bin not found in repository"
    exit 1
fi

################################################################################
# Step 5: Configure USB permissions and check device
################################################################################
print_info "Configuring USB permissions for SDR access..."

# Add user to necessary groups
sudo usermod -a -G plugdev,usb $USER 2>/dev/null || true

# Create udev rule for USRP devices (in case it wasn't created during provisioning)
sudo tee /etc/udev/rules.d/10-usrp.rules > /dev/null << 'EOF'
# USRP B210/B220/B200 devices
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0020", MODE:="0666", GROUP:="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0021", MODE:="0666", GROUP:="plugdev"
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0022", MODE:="0666", GROUP:="plugdev"
EOF

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Wait a moment for udev rules to take effect
sleep 2

print_info "Checking for connected LibreSDR device..."

# Source SDR device configuration if available
if [ -f "/vagrant/.sdr_config" ]; then
    source "/vagrant/.sdr_config"
fi

# Source SDR device manager utility
if [ -f "/vagrant/shared/utils/sdr_device_manager.sh" ]; then
    source "/vagrant/shared/utils/sdr_device_manager.sh"
fi

if lsusb | grep -i "Ettus Research"; then
    print_success "LibreSDR device detected via USB"

    # Validate device assignment if expected serial is configured
    if [ -n "$EXPECTED_SDR_SERIAL" ] && command -v validate_sdr_assignment >/dev/null 2>&1; then
        if ! validate_sdr_assignment "$EXPECTED_SDR_SERIAL" "legitimate2"; then
            print_error "SDR device validation failed"
            print_info "Please ensure SDR #2 (serial: $EXPECTED_SDR_SERIAL) is connected to this VM"
            SDR_PRESENT=false
        else
            SDR_PRESENT=true
        fi
    else
        print_info "SDR device detected but serial validation not configured"
        print_info "Configure EXPECTED_SDR_SERIAL in /vagrant/.sdr_config for proper validation"
        SDR_PRESENT=true
    fi
else
    print_info "LibreSDR device not detected during provisioning."
    print_info "This is expected - attach SDR device to VM after startup"
    print_info "SDR configuration will be skipped for now"
    print_info "Run 'source /vagrant/.sdr_config' to see configuration instructions"
    SDR_PRESENT=false
fi

if [ "$SDR_PRESENT" = true ]; then
    ################################################################################
    # Step 6: Find and validate assigned device using UHD
    ################################################################################
    print_info "Searching for UHD devices..."

    # Get the specific device assigned to this VM
    if [ -n "$EXPECTED_SDR_SERIAL" ]; then
        print_info "Looking for device with serial: $EXPECTED_SDR_SERIAL"
        device_info=$(uhd_find_devices 2>/dev/null | grep "serial: $EXPECTED_SDR_SERIAL")

        if [ -z "$device_info" ]; then
            print_error "Expected SDR device (serial: $EXPECTED_SDR_SERIAL) not found"
            print_info "Available devices:"
            uhd_find_devices 2>/dev/null || echo "No UHD devices detected"
            print_info "Please ensure SDR #2 is properly assigned to this VM"
            exit 1
        else
            print_success "Found assigned SDR device: $EXPECTED_SDR_SERIAL"
            uhd_find_devices 2>/dev/null
        fi
    else
        print_info "No expected serial configured, showing all devices:"
        uhd_find_devices 2>/dev/null || echo "No UHD devices detected"
        print_info "Configure EXPECTED_SDR_SERIAL in /vagrant/.sdr_config for targeted device operation"
    fi

    ################################################################################
    # Step 7: Load custom FPGA image to assigned device only
    ################################################################################
    print_info "Loading custom FPGA image to assigned LibreSDR device..."

    # Only load FPGA to the specific device assigned to this VM
    if [ -n "$EXPECTED_SDR_SERIAL" ]; then
        print_info "Loading FPGA image for device serial: $EXPECTED_SDR_SERIAL"
        if uhd_image_loader --args="serial=$EXPECTED_SDR_SERIAL" 2>/dev/null; then
            print_success "FPGA image loaded for device $EXPECTED_SDR_SERIAL"
        else
            print_info "FPGA loading failed for $EXPECTED_SDR_SERIAL (may already have correct image)"
        fi
    else
        print_info "Skipping FPGA loading - no specific device configured"
        print_info "Configure EXPECTED_SDR_SERIAL in /vagrant/.sdr_config to enable FPGA loading"
    fi

    ################################################################################
    # Step 8: Probe assigned device to verify functionality
    ################################################################################
    print_info "Probing assigned LibreSDR device to verify configuration..."

    # Only probe the specific device assigned to this VM
    if [ -n "$EXPECTED_SDR_SERIAL" ]; then
        print_info "Probing device serial: $EXPECTED_SDR_SERIAL"
        if uhd_usrp_probe --args="serial=$EXPECTED_SDR_SERIAL" 2>/dev/null; then
            print_success "Device $EXPECTED_SDR_SERIAL probe successful"
        else
            print_error "Device $EXPECTED_SDR_SERIAL probe failed"
            print_info "Check device connection and try again"
            exit 1
        fi
        print_success "Device probe completed successfully"
    else
        print_info "Skipping device probe - no specific device configured"
        print_info "Configure EXPECTED_SDR_SERIAL in /vagrant/.sdr_config to enable device probing"
    fi
else
    print_info "Skipping device-specific configuration (no SDR detected)"
    print_info "Run SDR setup manually after attaching device to VM"
fi

################################################################################
# Cleanup
################################################################################
print_info "Cleaning up temporary files..."
cd ~
sudo rm -rf "$TEMP_DIR" "$LIBRESDR_DIR"
print_success "Cleanup completed"

################################################################################
# Final message
################################################################################
echo ""
print_success "=============================================="
print_success "LibreSDR B210/B220 Setup Complete!"
print_success "=============================================="
echo ""
print_info "Your LibreSDR device is now ready to use."
print_info "You can verify functionality with: uhd_usrp_probe --args=\"type=b200\""
echo ""
