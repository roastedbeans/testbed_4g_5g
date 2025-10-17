# SDR Device Conflict Prevention Guide

## Overview

This guide explains how to properly configure SDR (Software Defined Radio) devices to prevent conflicts between multiple VMs in the cellular network testing environment.

## Problem Statement

When running multiple VMs (legitimate, legitimate2, false) simultaneously, each VM requires its own dedicated SDR device. SDR devices cannot be shared between VMs due to USB passthrough limitations and device access conflicts.

## Solution Architecture

### Device Assignment Strategy

- **legitimate VM**: Uses SDR Device #1 (Primary base station)
- **legitimate2 VM**: Uses SDR Device #2 (Handover testing)
- **false VM**: Uses SDR Device #3 (Rogue base station)

### Hardware Requirements

- **3 separate USRP B210 or B220 devices** (or compatible LibreSDR devices)
- **3 separate USB ports** on the host machine
- **Unique serial numbers** for each device

## Configuration Steps

### Step 1: Identify SDR Device Serial Numbers

For each SDR device, determine its unique serial number:

```bash
# Connect one SDR device at a time to your host
# Run this command to identify the serial number
uhd_find_devices
```

Example output:
```
[INFO] [UHD] linux; GNU C++ version 11.4.0; Boost_107400; UHD_4.1.0.5-0-g1234567
--------------------------------------------------
-- UHD Device 0
--------------------------------------------------
Device Address:
    serial: 12345678  # ← This is the serial number
    name: MyB210
    type: b200
```

### Step 2: Configure Each VM

For each VM, edit the `.sdr_config` file to set the expected serial number:

#### legitimate/.sdr_config
```bash
# Set this to your SDR #1 serial number
EXPECTED_SDR_SERIAL="12345678"
```

#### legitimate2/.sdr_config
```bash
# Set this to your SDR #2 serial number
EXPECTED_SDR_SERIAL="87654321"
```

#### false/.sdr_config
```bash
# Set this to your SDR #3 serial number
EXPECTED_SDR_SERIAL="11223344"
```

### Step 3: Validate Configuration

Run the validation script to ensure proper setup:

```bash
# Validate all VMs
./shared/utils/validate_sdr_setup.sh

# Validate specific VM
./shared/utils/validate_sdr_setup.sh legitimate
```

## VM Startup Sequence

### Correct Startup Order

1. **Start legitimate VM first** (with SDR #1)
2. **Start legitimate2 VM second** (with SDR #2)
3. **Start false VM last** (with SDR #3)

### USB Device Assignment

For each VM, follow these steps in VirtualBox:

1. Start the VM: `vagrant up <vm_name>`
2. Connect the appropriate SDR device to a USB port
3. In VirtualBox GUI:
   - Go to VM menu → **Devices** → **USB**
   - Select the SDR device: **"Ettus Research LLC USRP B210"**
   - Verify in VM: `uhd_find_devices`

### Validation Commands

Inside each VM, verify correct device assignment:

```bash
# Check USB device detection
lsusb | grep Ettus

# Check UHD device detection
uhd_find_devices

# Validate device serial
source /vagrant/.sdr_config
validate_sdr_assignment "$EXPECTED_SDR_SERIAL" "$(hostname)"
```

## Frequency Configuration

To prevent RF interference, each base station uses different frequencies:

| VM | Primary Frequency | Secondary Frequencies |
|----|------------------|----------------------|
| legitimate | 3450 MHz | 3550 MHz, 3650 MHz |
| legitimate2 | 3550 MHz | 3450 MHz, 3650 MHz |
| false | 3650 MHz | 3450 MHz, 3600 MHz |

This frequency separation enables proper handover testing between legitimate base stations.

## Troubleshooting

### Common Issues

#### 1. "Device already in use" Error

**Symptoms**: VM fails to start with device access errors

**Cause**: SDR device assigned to another running VM

**Solution**:
- Stop all VMs: `vagrant halt`
- Disconnect all SDR devices
- Start VMs one at a time with proper device assignment

#### 2. Wrong Serial Number

**Symptoms**: Validation fails with "serial validation failed"

**Solution**:
- Check actual device serial: `uhd_find_devices`
- Update `.sdr_config` with correct serial number
- Re-run validation script

#### 3. USB Device Not Appearing

**Symptoms**: SDR device not visible in VirtualBox USB menu

**Solutions**:
- Try different USB port on host
- Check USB cable and power supply
- Restart VirtualBox/Vagrant
- Check host system logs for USB issues

#### 4. Multiple Devices Detected

**Symptoms**: Validation shows multiple SDR devices in one VM

**Cause**: Incorrect USB device assignment or device conflict

**Solution**:
- Ensure only one SDR device is assigned per VM
- Check VirtualBox USB device assignments
- Use different USB ports for each device

### Diagnostic Commands

```bash
# Check all SDR configurations
./shared/utils/validate_sdr_setup.sh

# List USB devices on host
VBoxManage list usbhost

# Check VM USB assignments
VBoxManage showvminfo <vm_name> | grep USB

# Debug UHD issues
uhd_find_devices --verbose
```

## Best Practices

### Device Management

1. **Label your SDR devices** physically with serial numbers
2. **Use dedicated USB ports** for each device
3. **Document serial number assignments** for your setup
4. **Test device detection** before running experiments

### VM Management

1. **Start VMs in correct order**: legitimate → legitimate2 → false
2. **Stop VMs gracefully** to release USB devices
3. **Monitor device assignments** during operation
4. **Validate setup** before running cellular network tests

### Performance Optimization

1. **Use USB 3.0 ports** when available
2. **Ensure adequate power supply** for SDR devices
3. **Minimize USB hub usage** (direct connection preferred)
4. **Monitor CPU/memory usage** during operation

## Files Reference

- `shared/utils/sdr_device_manager.sh`: SDR device management utilities
- `shared/utils/validate_sdr_setup.sh`: SDR setup validation script
- `*/.sdr_config`: VM-specific SDR configuration files
- `*/Vagrantfile`: VM USB configuration (with conflict prevention)

## Support

If you encounter SDR device conflicts:

1. Run the validation script: `./shared/utils/validate_sdr_setup.sh`
2. Check VirtualBox USB device assignments
3. Verify serial numbers in `.sdr_config` files
4. Ensure correct VM startup sequence
5. Review troubleshooting section above
