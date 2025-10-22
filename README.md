# False Base Station Attack Infrastructure

A comprehensive research environment for studying cellular network security through false base station attacks. This project provides three isolated VM environments with dedicated hardware SDRs for controlled security research.

## Project Structure

```
attacks/
├── host/                           # Host management scripts
│   ├── start.sh                    # Start VMs
│   ├── stop.sh                     # Stop VMs
│   ├── ssh.sh                      # SSH access to VMs
│   ├── validate.sh                 # Setup validation
│   └── sdr_attach.sh               # SDR device management
│
├── legitimate/                     # Legitimate base station VM (dual BS)
│   ├── Vagrantfile
│   ├── provision.sh
│   ├── install/                    # Installation scripts
│   │   ├── sdr.sh                  # SDR drivers
│   │   ├── open5gs.sh              # Open5GS core network
│   │   └── srsran-4g.sh            # srsRAN 4G base station
│   ├── scripts/                    # Runtime scripts
│   │   └── subscriber.sh           # Subscriber management
│   └── configs/                    # Configuration files
│       ├── open5gs/                # Open5GS core network configs
│       └── srsran/                  # srsRAN configurations
│           ├── legitimate/         # BS #1 configs (SDR #1)
│           └── legitimate2/        # BS #2 configs (SDR #2)
│
├── false/                          # False base station VM
│   ├── Vagrantfile
│   ├── provision.sh
│   ├── install/                    # Installation scripts
│   │   ├── sdr.sh                  # SDR drivers
│   │   └── srsran-4g.sh            # srsRAN 4G rogue station
│   ├── scripts/                    # Runtime scripts
│   │   ├── attack_config.sh        # Attack profiles
│   │   └── start_false_bs.sh       # Start rogue base station
│   └── configs/                    # Configuration files
│
├── shared/                         # Shared utilities (for VMs)
│
├── sdr_manager.sh                  # Unified SDR device management
├── SDR_MANAGER_README.md           # SDR manager documentation
│
├── README.md                       # Main project documentation
├── setup.md                        # Setup and configuration guide
└── attacks.md                      # Attack scenarios and countermeasures
```

## ⚠️ Legal Disclaimer

**CRITICAL: READ BEFORE USE**

Operating a false base station (IMSI catcher, rogue eNodeB/gNodeB) without proper authorization is **ILLEGAL** in most jurisdictions and may result in:

- **Criminal prosecution**
- **Heavy fines** (potentially millions of dollars)
- **Imprisonment**
- **Equipment seizure**
- **FCC/regulatory violations**

This project is designed **EXCLUSIVELY** for:
- Controlled research environments
- Isolated RF-shielded laboratories
- Educational demonstrations with proper authorization
- Security research by authorized professionals

**YOU ARE SOLELY RESPONSIBLE** for ensuring compliance with all applicable laws and regulations in your jurisdiction.

## Architecture Overview

### System Components

```
┌──────────────────────────────────────┐
│     Legitimate Base Station VM       │
│  ┌────────────────────────────────┐  │
│  │ Open5GS Core Network           │  │
│  │  • MME (4G) / AMF (5G)         │  │
│  │  • HSS/UDM, SMF, UPF, etc.     │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ srsRAN Base Stations           │  │
│  │  • eNodeB (4G LTE)             │  │
│  │  • gNodeB (5G NR)              │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ LibreSDR B220 #1               │  │
│  │  TX Gain: 60-70 dB             │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
                 ↕
        UE (Phone/Modem)
                 ↕
┌──────────────────────────────────────┐
│      False Base Station VM           │
│  ┌────────────────────────────────┐  │
│  │ srsRAN (Rogue)                 │  │
│  │  • Rogue eNodeB (4G)           │  │
│  │  • Rogue gNodeB (5G)           │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ Attack Modes                   │  │
│  │  • IMSI Catcher                │  │
│  │  • Downgrade Attack            │  │
│  │  • Man-in-the-Middle           │  │
│  │  • Denial of Service           │  │
│  └────────────────────────────────┘  │
│  ┌────────────────────────────────┐  │
│  │ LibreSDR B220 #2               │  │
│  │  TX Gain: 75-85 dB (stronger)  │  │
│  └────────────────────────────────┘  │
└──────────────────────────────────────┘
```

### Key Features

- **Three VM Architecture**: Separate VMs for primary legitimate, secondary legitimate, and false base stations
- **4G & 5G Support**: Both LTE and NR technologies
- **Switchable Modes**: Toggle between 4G and 5G on legitimate BS
- **Multiple Attack Vectors**: IMSI catching, downgrade, MITM, DoS
- **Signal Management**: Dynamic TX gain adjustment for handover demonstrations
- **Timed Startup**: Configurable delay for false BS activation
- **Real-time Monitoring**: Track UE handover events

## Prerequisites

### Hardware Requirements

1. **Three LibreSDR B220 mini SDRs**
   - Must be distinguishable (different serial numbers preferred)
   - Proper antennas for your frequency bands
   - USB 3.0 cables

2. **Host Computer**
   - CPU: 4+ cores (8+ recommended)
   - RAM: 16 GB minimum (32 GB recommended)
   - USB 3.0 ports
   - Storage: 100 GB free space

3. **UE (User Equipment)**
   - Test phone or LTE/5G modem
   - SIM card (programmable test SIM recommended)

4. **RF Environment**
   - **MANDATORY**: RF-shielded enclosure or Faraday cage
   - Attenuators to control signal strength
   - Isolated from commercial cellular networks

### Software Requirements

- **Host OS**: Windows, macOS, or Linux
- **VirtualBox**: 7.0 or later
- **Vagrant**: 2.3 or later
- **Git**: For cloning the repository

## Installation

### 1. Clone Repository

```bash
git clone <repository-url>
cd attacks
```

### 2. Identify SDR Devices

On your host machine, identify both SDR devices:

```bash
# Linux/macOS
lsusb | grep -i ettus

# Windows (PowerShell)
Get-PnpDevice | Where-Object {$_.FriendlyName -like "*USRP*"}
```

For detailed info:
```bash
lsusb -v -d 2500:0020 2>&1 | grep -E "idVendor|idProduct|iSerial"
```

**⚠️ IMPORTANT**: Each VM requires its own dedicated SDR device. Multiple VMs cannot share the same SDR device. See [SDR Conflict Prevention Guide](docs/SDR_CONFLICT_PREVENTION.md) for detailed setup instructions.

### 3. SDR Device Management

Use the unified SDR manager for simple device attachment:

```bash
# Check available SDR devices
./sdr_manager.sh check

# Show current device assignments
./sdr_manager.sh status

# Auto-attach devices to running VMs
./sdr_manager.sh auto

# Manual attachment
./sdr_manager.sh attach legitimate
./sdr_manager.sh attach legitimate2
./sdr_manager.sh attach false
```

See [SDR_MANAGER_README.md](SDR_MANAGER_README.md) for complete usage instructions.

### 4. Add User to vboxusers Group

**CRITICAL**: This step is required for USB passthrough to work.

```bash
# Add your user to the vboxusers group
sudo usermod -aG vboxusers $USER

# LOG OUT AND LOG BACK IN for the change to take effect
# You will need to close your terminal and open a new one
```

Verify you're in the group:
```bash
groups | grep vboxusers
```

Note the serial numbers or USB IDs for both devices.

### 5. Configure USB Passthrough

**✅ USB passthrough has already been configured** for your detected USRP B210 devices.

If you want to modify the USB configuration manually, edit `Vagrantfile.legitimate` and `Vagrantfile.false`.

### 7. Start Legitimate Base Station

```bash
# From the attacks directory
./START_VMS.sh legitimate
```

Wait for provisioning to complete (15-30 minutes).

### 8. Start False Base Station

```bash
# In a new terminal
./START_VMS.sh false
```

## Usage

### Basic Workflow

#### Step 1: Configure Legitimate BS

SSH into the legitimate BS VM:

```bash
vagrant ssh --vagrantfile=Vagrantfile.legitimate
```

Register your UE's IMSI in Open5GS:
- Access WebUI: http://192.168.56.10:9999
- Login: `admin` / `1423`
- Add subscriber with your SIM's IMSI and Ki

Start the legitimate base station (4G):

```bash
sudo switch_network.sh 4g
sudo srsenb /etc/srsran/legitimate/enb_4g.conf
```

#### Step 2: Connect UE

Power on your UE (phone/modem) and verify it connects to the legitimate BS. You should see connection logs in the srsenb output.

#### Step 3: Configure False BS Attack

In a new terminal, SSH into the false BS VM:

```bash
vagrant ssh --vagrantfile=Vagrantfile.false
```

Select an attack profile:

```bash
sudo attack_config.sh list              # List available attacks
sudo attack_config.sh set imsi_catcher  # Configure IMSI catcher
```

#### Step 4: Start Monitoring

In a third terminal (on false BS or legitimate BS):

```bash
sudo monitor_handover.sh
```

#### Step 5: Launch False BS

Start the false base station with timed delay:

```bash
# 15 second delay (default)
sudo start_false_bs.sh

# Custom delay
sudo start_false_bs.sh -d 20

# Specific attack mode
sudo start_false_bs.sh -a downgrade

# Immediate start (no delay)
sudo start_false_bs.sh --no-delay
```

#### Step 6: Observe Handover

Watch the monitor as the UE hands over from the legitimate to false BS due to stronger signal strength. The false BS will execute the configured attack.

### Advanced Usage

#### Signal Strength Management

Configure signal strengths for predictable handover:

```bash
# Preset for handover demonstration
sudo signal_manager.sh preset-handover

# Custom signal strengths
sudo signal_manager.sh set-legitimate 65
sudo signal_manager.sh set-false 80

# Gradual signal increase
sudo signal_manager.sh ramp-up-false

# Interactive adjustment
sudo adjust_signal.sh demo
```

#### Network Switching (Legitimate BS)

Switch between 4G and 5G:

```bash
# Check current mode
sudo switch_network.sh status

# Switch to 4G
sudo switch_network.sh 4g
sudo srsenb /etc/srsran/legitimate/enb_4g.conf

# Switch to 5G  
sudo switch_network.sh 5g
sudo gnb -c /etc/srsran/legitimate/gnb_5g.yml
```

#### Attack Configuration

View and modify attack settings:

```bash
# Show current configuration
sudo attack_config.sh show

# Set attack profile
sudo attack_config.sh set imsi_catcher
sudo attack_config.sh set downgrade
sudo attack_config.sh set mitm
sudo attack_config.sh set dos

# Reset to defaults
sudo attack_config.sh reset
```

## Attack Profiles

### 1. IMSI Catcher

**Purpose**: Capture subscriber identities (IMSI, IMEI, IMEISV)

**Method**:
- Disable encryption (EEA0/EIA0)
- Request identity from UEs
- Log all captured identities

**Usage**:
```bash
sudo attack_config.sh set imsi_catcher
sudo start_false_bs.sh
```

**Output**: `/tmp/imsi_catcher_identities.log`

### 2. Downgrade Attack

**Purpose**: Force UE to use weak or no encryption

**Method**:
- Prioritize weak algorithms (EEA0, EEA1)
- Reject strong encryption requests
- Log negotiated security parameters

**Usage**:
```bash
sudo attack_config.sh set downgrade
sudo start_false_bs.sh
```

**Output**: `/tmp/downgrade_attack.log`

### 3. Man-in-the-Middle (MITM)

**Purpose**: Intercept and analyze UE traffic

**Method**:
- Relay traffic to real core (optional)
- Capture all packets (PCAP)
- Deep packet inspection

**Usage**:
```bash
sudo attack_config.sh set mitm
sudo start_false_bs.sh
```

**Output**: `/tmp/mitm_full_capture.pcap`

### 4. Denial of Service (DoS)

**Purpose**: Prevent UE from accessing network

**Method**:
- Reject attach requests
- Disrupt existing connections
- Resource exhaustion

**Usage**:
```bash
sudo attack_config.sh set dos
sudo start_false_bs.sh
```

**Output**: `/tmp/dos_attack.log`

## Configuration Files

### Legitimate BS

- `/etc/srsran/legitimate/enb_4g.conf` - 4G eNodeB configuration
- `/etc/srsran/legitimate/gnb_5g.yml` - 5G gNodeB configuration
- `/etc/open5gs/mme.yaml` - 4G MME configuration
- `/etc/open5gs/amf.yaml` - 5G AMF configuration

### False BS

- `/etc/srsran/false/enb_4g_rogue.conf` - Rogue eNodeB configuration
- `/etc/srsran/false/gnb_5g_rogue.yml` - Rogue gNodeB configuration
- `/opt/configs/false/attack_modes.conf` - Attack modes configuration
- `/opt/attack_profiles/*.conf` - Individual attack profiles

## Troubleshooting

### SDR Not Detected

```bash
# Check if UHD can see the device
uhd_find_devices

# Check USB connection
lsusb | grep -i ettus

# Reload FPGA image
uhd_image_loader --args="type=b200"
```

### SDR Installation Fails During Provisioning

**Error**: "This script should not be run as root. Please run as a normal user."

**Cause**: The SDR installation script must run as the `vagrant` user, not root.

**Solution**: This is automatically handled by the provisioning script. The provisioning has been updated to run the SDR installation as the correct user. If you encounter this error, the fix is already in place.

### No UE Connection

1. Verify PLMN settings match (MCC=001, MNC=01)
2. Check SIM is registered in Open5GS WebUI
3. Verify signal strength: `uhd_usrp_probe`
4. Check logs: `tail -f /tmp/legitimate_enb.log`

### Handover Not Occurring

1. Verify false BS has higher TX gain
2. Check signal levels: `sudo signal_manager.sh status`
3. Increase false BS gain: `sudo signal_manager.sh set-false 85`
4. Check UE supports the frequency band

### Core Network Issues

```bash
# Check service status
sudo systemctl status open5gs-mmed  # 4G
sudo systemctl status open5gs-amfd  # 5G

# Restart services
sudo systemctl restart open5gs-*

# Check MongoDB
sudo systemctl status mongod
```

## Log Files

### Legitimate BS
- `/tmp/legitimate_enb.log` - eNodeB logs
- `/tmp/legitimate_gnb.log` - gNodeB logs
- `/tmp/legitimate_enb_mac.pcap` - MAC layer capture
- `/var/log/open5gs/mme.log` - MME logs

### False BS
- `/tmp/false_enb.log` - Rogue eNodeB logs
- `/tmp/false_bs_logs/` - General logs directory
- `/tmp/imsi_catcher_identities.log` - Captured identities
- `/tmp/handover_events.log` - Handover tracking

## Safety Guidelines

1. **RF Shielding**: ALWAYS use RF-shielded enclosure
2. **Low Power**: Keep TX gain at minimum necessary levels
3. **Isolated Network**: No connection to real cellular networks
4. **Monitoring**: Constantly monitor for unintended emissions
5. **Emergency Stop**: Be prepared to immediately power off
6. **Documentation**: Log all experiments for accountability

## Contributing

This is a research tool. Contributions should focus on:
- Security research capabilities
- Safety features
- Documentation improvements
- Bug fixes

## References

- [srsRAN Documentation](https://docs.srsran.com/)
- [Open5GS Documentation](https://open5gs.org/open5gs/docs/)
- [3GPP Specifications](https://www.3gpp.org/specifications)
- [Cellular Security Research Papers](https://scholar.google.com/)

## License

This project is provided for research and educational purposes. See LICENSE file for details.

## Support

For issues and questions:
1. Check troubleshooting section
2. Review log files
3. Consult srsRAN/Open5GS documentation
4. Open an issue on the repository

---

**Remember**: With great power comes great responsibility. Use this tool ethically and legally.

