# SDR USB Permissions Fix Guide

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
EOF

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger

# Reattach USB device via VirtualBox menu
# Then test:
sudo uhd_find_devices
sudo uhd_usrp_probe --args="type=b200"
```

### Solution 3: Run SDR Setup with Sudo

As a workaround, run the SDR commands with sudo:

```bash
# SSH into VM
./ssh.sh legitimate

# Run UHD commands with sudo
sudo uhd_find_devices
sudo uhd_usrp_probe --args="type=b200"
sudo uhd_image_loader --args="type=b200"
```

## Verification Steps

### Check USB Device Detection
```bash
# Should show Ettus Research device
lsusb | grep 2500

# Should show device permissions
ls -la /dev/bus/usb/* | grep 2500
```

### Check UHD Installation
```bash
# Check UHD version
uhd_find_devices --version

# Check if images are installed
ls /usr/share/uhd/images/ | grep fpga
```

### Test SDR Functionality
```bash
# Find devices
uhd_find_devices

# Probe device (main test)
uhd_usrp_probe --args="type=b200"

# Check FPGA image
uhd_image_loader --args="type=b200"
```

## Common Issues & Fixes

### Issue: "No UHD Devices Found"
**Fix:** USB device not attached to VM
- Check VirtualBox USB settings
- Try reattaching device via Devices → USB menu

### Issue: "insufficient permissions"
**Fix:** User lacks USB access permissions
- Run commands with `sudo`
- Fix user group membership
- Check udev rules

### Issue: Device disappears after VM operations
**Fix:** VirtualBox USB passthrough instability
- Reattach device via VirtualBox menu
- Restart VM
- Check host USB ports

## Prevention

### For Future VM Starts:

1. **Always attach USB devices manually** via VirtualBox menu after VM starts
2. **Run UHD commands with sudo** if permission issues persist
3. **Verify device attachment** before running SDR applications

### Host System Setup:

1. **Install VirtualBox Extension Pack**
2. **Add user to vboxusers group** on host
3. **Use USB 3.0 ports** for SDR devices
4. **Avoid USB hubs** if possible

## Testing SDR Functionality

Once permissions are fixed, test complete SDR functionality:

```bash
# 1. Find devices
uhd_find_devices

# 2. Probe device
uhd_usrp_probe --args="type=b200"

# 3. Start srsRAN (after configuration)
sudo srsenb /etc/srsran/legitimate/enb_4g.conf
```

## Success Indicators

✅ `lsusb` shows Ettus Research device
✅ `uhd_find_devices` finds USRP B210
✅ `uhd_usrp_probe` completes without permission errors
✅ srsRAN starts successfully
✅ UE can connect to network

If all these work, the SDR setup is complete and functional!
