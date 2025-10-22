# False Base Station (Rogue)

This directory contains the false/rogue base station VM configuration for attack demonstrations.

## ⚠️ Legal Warning

**CRITICAL: READ BEFORE USE**

Operating a false base station without proper authorization is **ILLEGAL** and may result in:

- Criminal prosecution
- Heavy fines (potentially millions of dollars)
- Imprisonment
- Equipment seizure
- FCC/regulatory violations

This VM is intended **EXCLUSIVELY** for:
- Controlled research environments
- Isolated RF-shielded laboratories
- Educational demonstrations with proper authorization

**YOU ARE SOLELY RESPONSIBLE** for ensuring compliance with all applicable laws and regulations.

## Components

- **srsRAN 4G**: Rogue LTE eNodeB base station
- **srsRAN 5G**: Rogue NR gNodeB base station (optional)
- **Attack Profiles**: Pre-configured attack modes
- **Signal Management**: TX/RX gain control for handover demonstrations

## Quick Start

1. **Start legitimate BS first:**
   ```bash
   ../start.sh legitimate
   ```

2. **Register test subscribers in legitimate BS WebUI**

3. **Start false BS:**
   ```bash
   cd false
   vagrant up
   ```

4. **Configure attack profile:**
   ```bash
   vagrant ssh
   sudo attack_config.sh list              # List attack profiles
   sudo attack_config.sh set imsi_catcher  # Set attack mode
   ```

5. **Start false base station:**
   ```bash
   sudo start_false_bs.sh  # With 15-second delay for handover demo
   ```

## Attack Profiles

- **IMSI Catcher**: Capture subscriber identities
- **Downgrade Attack**: Force weak encryption
- **Man-in-the-Middle**: Intercept and modify traffic
- **Denial of Service**: Disrupt legitimate network access

## Configuration

### Network Configuration

- **Bridged Mode**: Gets IP from host network DHCP
- **SDR Device**: LibreSDR B220 #3 (automatic USB passthrough)
- **No Core Network**: Operates standalone or relays to legitimate core

### Files Structure

```
false/
├── Vagrantfile          # VM configuration
├── provision.sh         # Installation script
├── configs/
│   ├── attack_profiles/ # Attack configuration profiles
│   └── srsran/          # Rogue srsRAN configurations
├── scripts/             # Attack-specific scripts
└── install/             # Installation scripts
```

## Scripts

- `attack_config.sh` - Configure attack modes
- `start_false_bs.sh` - Start rogue BS with configurable delay
- `signal_manager.sh` - Manage signal strength for handover
- `monitor_handover.sh` - Monitor UE handover events

## Usage Examples

### IMSI Catcher Attack

```bash
# Configure IMSI catcher
sudo attack_config.sh set imsi_catcher

# Start with 20-second delay for handover demo
sudo start_false_bs.sh -d 20

# Monitor captured identities
sudo monitor_handover.sh
```

### Signal Management

```bash
# Setup for handover demonstration
sudo signal_manager.sh preset-handover

# Gradual signal increase
sudo signal_manager.sh ramp-up-false

# Interactive signal control
sudo adjust_signal.sh demo
```

## Operational Sequence

**IMPORTANT: Always follow this sequence:**

1. **Start legitimate BS first**
2. **Wait for UE to connect to legitimate BS**
3. **Register UE in legitimate BS WebUI**
4. **Start false BS**
5. **Configure attack profile**
6. **Start false BS attack**

## Troubleshooting

### SDR Device Issues

1. Check device detection: `vagrant ssh -c "uhd_find_devices"`
2. Manual attachment: VirtualBox GUI → Devices → USB → USRP B210 (the other one)
3. Verify permissions: `vagrant ssh -c "lsusb"`

### Attack Profile Issues

1. List available profiles: `sudo attack_config.sh list`
2. Check profile files: `ls /opt/attack_profiles/`
3. Verify configuration: `sudo attack_config.sh status`

### Handover Issues

1. Check signal strength: `sudo signal_manager.sh status`
2. Monitor handover events: `sudo monitor_handover.sh`
3. Adjust timing: `sudo start_false_bs.sh -d <seconds>`

## Security Considerations

- **Isolated Environment**: Use only in RF-shielded facilities
- **Limited Duration**: Run attacks for minimal time necessary
- **Proper Authorization**: Obtain all necessary permissions
- **Documentation**: Maintain detailed logs of all activities

## Support

For legitimate research purposes only. Contact project maintainers for technical issues in controlled environments.
