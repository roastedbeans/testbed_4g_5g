# False Base Station - Host Installation

This directory contains a false base station setup that runs directly on your host Linux system, without Vagrant virtualization.

## ⚠️ Legal Warning

**Operating a false base station is ILLEGAL without proper authorization.** This system is for CONTROLLED RESEARCH ENVIRONMENTS ONLY.

## Prerequisites

- Ubuntu 24.04 LTS (or compatible Linux distribution)
- LibreSDR B210/B220 device (SDR #3)
- Root/sudo access
- Internet connection for software installation

## Quick Start

1. **Clone or extract this directory** to your desired location
2. **Make scripts executable:**
   ```bash
   chmod +x setup_host.sh
   chmod +x provision.sh
   chmod +x scripts/*.sh
   ```

3. **Run the host setup:**
   ```bash
   ./setup_host.sh
   ```

4. **Attach SDR device** (LibreSDR B210/B220 - SDR #3)

5. **Configure attack mode:**
   ```bash
   ./scripts/attack_config.sh list          # List available attacks
   ./scripts/attack_config.sh set imsi_catcher  # Set IMSI catcher mode
   ```

6. **Start false base station:**
   ```bash
   ./scripts/start_false_bs.sh              # Start with 15s delay
   ./scripts/start_false_bs.sh --no-delay   # Start immediately
   ```

## Directory Structure

```
false_host/
├── setup_host.sh          # Host setup script (main entry point)
├── provision.sh           # Installation and configuration script
├── install/               # Installation scripts
│   ├── sdr.sh            # UHD/LibreSDR driver setup
│   └── srsran-4g.sh      # srsRAN 4G installation
├── configs/               # Configuration files
│   └── attack_profiles/   # Attack-specific configurations
├── scripts/               # Control and management scripts
│   ├── start_false_bs.sh         # Start the false base station
│   ├── attack_config.sh          # Configure attack profiles
│   ├── signal_manager.sh         # Signal strength management
│   ├── adjust_signal.sh          # Interactive signal adjustment
│   └── monitor_handover.sh       # Monitor UE handovers
├── .sdr_config            # SDR device configuration
└── README_HOST.md         # This file
```

## Configuration

### SDR Device Setup

Edit `.sdr_config` to configure your SDR device:
```bash
# SDR Device Configuration for Host
VM_ROLE="false"                          # Host installation
EXPECTED_SDR_SERIAL="YOUR_SERIAL_HERE"   # SDR #3 serial number
```

### Attack Profiles

The system uses optimized attack profile configurations:

- **`enb_4g_rogue.conf`**: Main eNodeB configuration with higher TX gain (80 dB) and rogue PLMN
- **`rr.conf`**: Radio resources optimized for false base station operation
- **`rb.conf`**: Radio bearers configured for attack modes
- **`sib.conf`**: System information with `cell_barred = "NotBarred"` and lower `q_rx_lev_min = -70`

Available attack modes:
- **imsi_catcher**: Capture IMSI/IMEI identities
- **downgrade**: Force weak encryption (A5/1)
- **mitm**: Man-in-the-middle attack
- **dos**: Denial of service

## Important Notes

1. **Always start legitimate BS first** before running the false BS
2. The false BS uses higher TX gain (80 dB) to override legitimate signals
3. Monitor UE handovers with `./scripts/monitor_handover.sh`
4. Adjust signal strength with `./scripts/signal_manager.sh` or `./scripts/adjust_signal.sh`

## Troubleshooting

### SDR Device Not Detected
```bash
# Check USB devices
lsusb | grep Ettus

# Check UHD devices
uhd_find_devices

# Re-run SDR setup
./install/sdr.sh
```

### srsRAN Fails to Start
```bash
# Check configuration files
ls -la /etc/srsran/false/

# Check SDR device status
uhd_usrp_probe
```

### Permission Issues
```bash
# Add user to required groups
sudo usermod -a -G plugdev,usb $USER

# Reload udev rules
sudo udevadm control --reload-rules
sudo udevadm trigger
```

## Desktop Integration

The setup script creates desktop shortcuts for easy access:
- `Start False Base Station`: Launches the false BS
- `Attack Configuration`: Opens attack profile manager

**Note:** Update the paths in the desktop files to match your installation directory.

## Network Architecture

```
[Legitimate BS] <--connects--> [UE/Mobile Device] <--connects--> [False BS]
     ↑                                                            ↑
   Open5GS Core                                                Rogue eNodeB
   (MME/AMF)                                                  (Standalone)
```

The false BS appears as a stronger signal to UEs, causing handover from the legitimate network.

## Logs and Monitoring

- **srsRAN logs**: `/tmp/false_enb.log`
- **Attack logs**: `/tmp/false_bs_logs/`
- **PCAP files**: `/tmp/false_enb_*.pcap`

## Cleanup

To remove the false base station setup:
```bash
# Remove installed packages
sudo apt remove srsran

# Remove configuration files
sudo rm -rf /etc/srsran/false
sudo rm -rf /opt/attack_profiles
sudo rm -rf /opt/scripts

# Remove desktop shortcuts
rm ~/Desktop/start_false_bs.desktop
rm ~/Desktop/attack_config.desktop
```

## Support

This is research software. Use at your own risk and ensure compliance with local laws and regulations.
