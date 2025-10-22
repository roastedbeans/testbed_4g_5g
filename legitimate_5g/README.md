# Legitimate 5G Base Station

This directory contains the legitimate 5G base station VM configuration with full Open5GS core network and srsRAN Project 5G implementation.

## Components

- **Open5GS**: 4G MME + 5G AMF core network
- **srsRAN Project 5G**: gNodeB (5G NR) - PRIMARY FOCUS
- **srsRAN 4G**: eNodeB (4G LTE) - Secondary
- **LibreSDR B220**: SDR hardware support
- **Network Management**: Signal control and handover monitoring


## Quick Start

1. **Start the VM:**
   ```bash
   cd legitimate_5g
   vagrant up legitimate_5g
   ```

2. **Find VM IP address:**
   ```bash
   vagrant ssh legitimate_5g -c "ip addr show | grep 'inet ' | grep -v '127.0.0.1'"
   ```

3. **Access WebUI:**
   - URL: `http://<VM_IP>:9999`
   - Credentials: `admin` / `1423`

4. **Register test subscribers:**
   - Login to WebUI
   - Go to Subscribers section
   - Add test IMSI/IMSI ranges

5. **Start 5G NR network (primary):**
   ```bash
   vagrant ssh legitimate_5g
   sudo srsenb /etc/srsran/legitimate/gnb_5g.conf
   ```

6. **Or start 4G LTE network (secondary):**
   ```bash
   vagrant ssh legitimate_5g
   sudo srsenb /etc/srsran/legitimate/enb_4g.conf
   ```

## Configuration

### Network Configuration

- **Bridged Mode**: Gets IP from host network DHCP
- **WebUI Access**: Available from any device on network
- **SDR Device**: LibreSDR B220 #1 (5G capable, automatic USB passthrough)

### Files Structure

```
legitimate_5g/
├── Vagrantfile          # VM configuration (5G focus)
├── provision.sh         # Installation script (11 phases)
├── .sdr_config          # SDR device configuration
├── configs/
│   ├── open5gs/         # Open5GS configurations (4G+5G)
│   └── srsran/          # srsRAN configurations (5G primary, 4G secondary)
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
