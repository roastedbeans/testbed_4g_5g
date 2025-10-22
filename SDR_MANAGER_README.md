# SDR Device Manager

A unified tool for managing SDR (Software Defined Radio) devices across all VMs in the cellular network testing environment.

## Overview

The `sdr_manager.sh` script provides a simple and straightforward way to:
- Check available SDR devices on your host
- Attach/detach SDR devices to/from VMs
- View current device assignments
- Automatically manage device attachments

## SDR Device Assignments

| VM | SDR Serial(s) | Device(s) | Purpose |
|----|---------------|-----------|---------|
| `legitimate` | `C5XA7X9 + P44SEGH` | SDR #1 + SDR #2 | 4G LTE Primary Base Station (both SDRs) |
| `legitimate2` | None | None | No SDR assigned (devices moved to legitimate) |
| `false` | `VRFKZRP` | SDR #3 | Rogue/Attack Base Station |
| `legitimate_5g` | `C5XA7X9` | SDR #1 | 5G NR Base Station (shares with legitimate) |

## Usage

### Basic Commands

```bash
# Check available SDR devices on host
./sdr_manager.sh check

# Show current device assignments and VM status
./sdr_manager.sh status

# Attach SDR device(s) to a specific VM
./sdr_manager.sh attach legitimate    # Attach both C5XA7X9 + P44SEGH
./sdr_manager.sh attach false         # Attach VRFKZRP
# legitimate2 has no SDR devices assigned

# Detach SDR device from a VM
./sdr_manager.sh detach legitimate

# Auto-attach correct devices to all running VMs
./sdr_manager.sh auto

# Show help
./sdr_manager.sh help
```

### Typical Workflow

1. **Start your VMs:**
   ```bash
   ./start.sh legitimate    # Start legitimate VM (gets both SDRs)
   ./start.sh false         # Start rogue VM
   # legitimate2 no longer needs SDR devices
   ```

2. **Attach SDR devices:**
   ```bash
   ./sdr_manager.sh auto    # Auto-attach all devices
   # OR manually:
   ./sdr_manager.sh attach legitimate    # Attach both C5XA7X9 + P44SEGH
   ./sdr_manager.sh attach false         # Attach VRFKZRP
   ```

3. **Verify devices are attached:**
   ```bash
   ./sdr_manager.sh status
   ```

4. **Test SDR functionality in VMs:**
   ```bash
   vagrant ssh legitimate -c "uhd_find_devices"
   vagrant ssh legitimate -c "uhd_usrp_probe --args=\"serial=C5XA7X9\""
   ```

## Device UUIDs

The script uses these VirtualBox device UUIDs (automatically configured):

- `C5XA7X9`: `fddf4ec5-214c-41bd-a5b7-4e846ade83b6`
- `P44SEGH`: `9006df15-5ae1-49a8-a6ba-785b5de167ed`
- `VRFKZRP`: `1617671a-bc4b-49fb-9471-5f55315dbddc`

If your devices change, update the `SDR_UUIDS` array in the script.

## Troubleshooting

### Device Not Detected
```bash
# Check if devices are visible to VirtualBox
./sdr_manager.sh check

# Try manual attachment via VirtualBox GUI
# VirtualBox → VM → Devices → USB → Select Ettus device
```

### VM Not Running
```bash
# Start the VM first
vagrant up legitimate
./sdr_manager.sh attach legitimate
```

### Permission Issues
```bash
# Make sure script is executable
chmod +x sdr_manager.sh
```

## Integration with Other Scripts

The SDR manager integrates with the existing workflow:

- **start.sh/stop.sh**: VM management
- **Vagrant provisioning**: Automatic SDR driver installation

## Important Notes

- **One device per VM**: Never attach the same SDR to multiple running VMs
- **Shared device**: `legitimate` and `legitimate_5g` share SDR #1 (run mutually exclusive)
- **USB passthrough**: Requires VirtualBox USB support
- **Device persistence**: Attachments don't survive VM reboots

## Quick Reference

```bash
# Most common commands
./sdr_manager.sh status     # Check what's attached
./sdr_manager.sh auto       # Auto-attach everything
./sdr_manager.sh check      # See available devices
```
