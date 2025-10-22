# Legitimate Base Station

This directory contains the legitimate base station VM configuration with full Open5GS core network and dual srsRAN 4G base stations.

## Components

- **Open5GS**: Complete 4G/5G core network implementation
- **srsRAN 4G (x2)**: Two LTE eNodeB base stations (dual SDR setup)
- **Open5GS WebUI**: Subscriber management interface
- **2x SDR Devices**: LibreSDR B220 #1 (C5XA7X9) + #2 (P44SEGH)

## Quick Start

1. **Start the VM:**
   ```bash
   cd legitimate
   vagrant up
   ```

2. **Find VM IP address:**
   ```bash
   vagrant ssh -c "ip addr show | grep 'inet ' | grep -v '127.0.0.1'"
   ```

3. **Access WebUI:**
   - URL: `http://<VM_IP>:9999`
   - Credentials: `admin` / `1423`

4. **Register test subscribers:**
   - Login to WebUI
   - Go to Subscribers section
   - Add test IMSI/IMSI ranges

5. **Attach SDR devices:**
   ```bash
   # From host machine
   ./sdr_manager.sh attach legitimate  # Attach both SDRs automatically
   # OR manually via VirtualBox GUI → Devices → USB
   ```

6. **Start base stations:**
   ```bash
   vagrant ssh

   # Start Base Station #1 (SDR #1 - C5XA7X9)
   sudo srsenb /etc/srsran/legitimate/enb_4g.conf

   # Start Base Station #2 (SDR #2 - P44SEGH)
   sudo srsenb /etc/srsran/legitimate2/enb_4g.conf
   ```

## Configuration

### Network Configuration

- **Bridged Mode**: Gets IP from host network DHCP
- **WebUI Access**: Available from any device on network
- **SDR Devices**: LibreSDR B220 #1 (C5XA7X9) + #2 (P44SEGH)

### Files Structure

```
legitimate/
├── Vagrantfile          # VM configuration
├── provision.sh         # Installation script
├── configs/
│   ├── open5gs/         # Open5GS configurations
│   └── srsran/          # srsRAN configurations
├── scripts/             # VM-specific scripts
└── install/             # Installation scripts
```

## Scripts

- `switch_network.sh` - Switch between 4G/5G modes
- `monitor_ue.sh` - Monitor connected UEs
- `webui_setup.sh` - WebUI configuration helper

## Troubleshooting

### WebUI Access

1. Check VM IP: `vagrant ssh -c "ip addr show"`
2. Verify service: `vagrant ssh -c "systemctl status open5gs-webui"`
3. Test connectivity: `vagrant ssh -c "curl -I http://localhost:9999"`

### SDR Issues

1. Check devices: `vagrant ssh -c "uhd_find_devices"` (should show 2 devices)
2. Manual attachment: VirtualBox GUI → Devices → USB → Select both USRP B210 devices
3. Automated attachment: `./sdr_manager.sh attach legitimate`

### srsRAN Issues

1. Check installation: `vagrant ssh -c "which srsenb"`
2. Verify configs: `vagrant ssh -c "ls /etc/srsran/legitimate/ /etc/srsran/legitimate2/"`
