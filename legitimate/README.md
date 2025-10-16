# Legitimate Base Station

This directory contains the legitimate base station VM configuration with full Open5GS core network and srsRAN base stations.

## Components

- **Open5GS**: Complete 4G/5G core network implementation
- **srsRAN 4G**: LTE eNodeB base station
- **srsRAN 5G**: NR gNodeB base station (optional)
- **Open5GS WebUI**: Subscriber management interface

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

5. **Start base station:**
   ```bash
   vagrant ssh
   sudo srsenb /etc/srsran/legitimate/enb_4g.conf  # 4G
   # OR
   sudo gnb -c /etc/srsran/legitimate/gnb_5g.yml    # 5G
   ```

## Configuration

### Network Configuration

- **Bridged Mode**: Gets IP from host network DHCP
- **WebUI Access**: Available from any device on network
- **SDR Device**: LibreSDR B220 #1 (automatic USB passthrough)

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

1. Check device: `vagrant ssh -c "uhd_find_devices"`
2. Manual attachment: VirtualBox GUI → Devices → USB → USRP B210

### srsRAN Issues

1. Check installation: `vagrant ssh -c "which srsenb"`
2. Verify configs: `vagrant ssh -c "ls /etc/srsran/legitimate/"`
