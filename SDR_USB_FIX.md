# SDR USB Permissions Fix

## Problem Description

The SDR setup script detects the LibreSDR device via USB (`lsusb` shows the device), but UHD commands fail with permission errors:

```
[ERROR] [USB] USB open failed: insufficient permissions.
No UHD Devices Found
```

## Root Cause

This is a **USB permissions issue** inside the VM. The device is properly attached via VirtualBox USB passthrough, but the user inside the VM doesn't have permission to access it.

## Solutions

### Solution 1: Manual USB Attachment (Immediate Fix)

1. **Stop the VM if running:**
   ```bash
   ./stop.sh legitimate
   ```

2. **Start VM without provisioning:**
   ```bash
   VAGRANT_VAGRANTFILE=legitimate/Vagrantfile vagrant up --no-provision
   ```

3. **SSH into VM:**
   ```bash
   ./ssh.sh legitimate
   ```

4. **In VirtualBox GUI:**
   - Go to VM window → **Devices** → **USB**
   - **Deselect** any USRP devices currently attached
   - **Select** "Ettus Research LLC USRP B210" to attach it
   - Confirm device is attached

5. **Back in VM terminal, test:**
   ```bash
   sudo uhd_find_devices          # Should find device
   sudo uhd_usrp_probe --args="type=b200"  # Should work
   ```

### Solution 2: Fix Permissions Inside VM

If Solution 1 doesn't work, fix permissions manually:

```bash
# SSH into VM
./ssh.sh legitimate

# Add user to USB groups
sudo usermod -a -G plugdev,usb vagrant

# Create udev rules
sudo tee /etc/udev/rules.d/10-usrp.rules > /dev/null << 'EOF'
SUBSYSTEM=="usb", ATTR{idVendor}=="2500", ATTR{idProduct}=="0020", MODE:="0666", GROUP:="plugdev"
