# Setup Guide - False Base Station Attack Infrastructure

Complete setup instructions for the false base station attack research environment.

## ⚠️ Prerequisites

### Legal Requirements
**THIS IS FOR AUTHORIZED RESEARCH ONLY**
- Unauthorized operation is ILLEGAL and may result in criminal prosecution
- Use only in RF-shielded environments with proper authorization

### Hardware Requirements
- **Three LibreSDR B220 mini SDRs** (Ettus Research USRP B210 compatible)
- **RF-shielded enclosure** (Faraday cage) - **MANDATORY**
- **Test UE** (phone/modem) with programmable SIM card
- **USB 3.0 ports** on host system (blue ports)
- **VirtualBox Extension Pack** installed

### Software Requirements
- **VirtualBox** (latest version)
- **Vagrant** (latest version)
- **Ubuntu/Debian host system**
- **VirtualBox Extension Pack** (download from virtualbox.org)

### System Requirements
- **Host RAM**: 24GB+ recommended (18GB VMs + host)
- **Host CPU**: 6+ cores recommended
- **Storage**: 80GB+ free space
- **USB**: USB 3.0 controller support

## 🚀 Quick Setup (30 Minutes)

### Step 1: SDR Device Configuration (5 minutes)

Identify your SDR devices:
```bash
lsusb | grep -i ettus
# Output should show three devices:
# Bus 001 Device 010: ID 2500:0020 Ettus Research LLC USRP B210
# Bus 001 Device 011: ID 2500:0020 Ettus Research LLC USRP B210
# Bus 001 Device 012: ID 2500:0020 Ettus Research LLC USRP B210
```

Note the serial numbers - each device should have a unique identifier.

### Step 2: USB Setup (2 minutes)

Add yourself to the vboxusers group:
```bash
sudo usermod -aG vboxusers $USER
```

**IMPORTANT**: Log out and log back in for the group change to take effect.

### Step 3: Start All VMs (20 minutes)

```bash
# Start all three VMs
./start.sh legitimate   # Primary legitimate BS
./start.sh legitimate2  # Secondary legitimate BS
./start.sh false        # False BS

# Wait for provisioning to complete (15-20 minutes)
# VMs will get IPs automatically via DHCP
```

### Step 4: Manual SDR Assignment (10 minutes)

**IMPORTANT**: Manual SDR assignment is required due to identical hardware.

```bash
# Open VirtualBox Manager and assign SDRs:
# 1. legitimate-base-station → Attach one USRP B210
# 2. legitimate-base-station2 → Attach second USRP B210
# 3. false-base-station → Attach third USRP B210
```

### Step 5: Verify Setup (5 minutes)

```bash
# SSH into each VM and verify SDR
./ssh.sh legitimate
uhd_find_devices  # Should show one device
exit

./ssh.sh legitimate2
uhd_find_devices  # Should show one device
exit

./ssh.sh false
uhd_find_devices  # Should show one device
exit

# Verify subscribers in legitimate VM
./ssh.sh legitimate
sudo subscriber.sh list  # Should show: 001010000118896
```

### Step 6: Start Networks (5 minutes)

```bash
# Start legitimate base station (includes core network)
./ssh.sh legitimate
sudo srsenb /etc/srsran/legitimate/enb_4g.conf

# Start legitimate2 base station (connects to shared core)
./ssh.sh legitimate2
sudo srsenb /etc/srsran/legitimate/enb_4g.conf

# Start false base station (ready for attacks)
./ssh.sh false
sudo /vagrant/false/scripts/start_false_bs.sh
```

### Step 7: Test with UE (2 minutes)

1. Program your test SIM with default subscriber credentials:
       - **IMSI**: 001010000118896
       - **Ki**: BD9044E60EFA8AD9052799E65D8AF224
       - **OPc**: C86FD5618B748B85BBC6515C7AEDB9A4

2. Insert SIM into test UE
3. UE should automatically register to the network

## 📋 Detailed Configuration

### SDR Device Configuration

Both SDRs are configured for USB 3.0 (xHCI) operation:

- **Vendor ID**: 0x2500
- **Product ID**: 0x0020
- **Serial**: 0000000004BE (both devices - VirtualBox handles assignment)
- **USB Version**: 3.0 (xHCI controller)

### Network Configuration

#### Primary Legitimate Base Station (legitimate)
- **IP**: DHCP assigned (typically 192.168.56.10)
- **Network Mode**: Bridged
- **PLMN**: 00101 (MCC=001, MNC=01)
- **TAC**: 7
- **EARFCN**: 3450 (Band 7, ~2.64 GHz)
- **PCI**: 1
- **Bandwidth**: 10 MHz

#### Secondary Legitimate Base Station (legitimate2)
- **IP**: DHCP assigned (typically 192.168.56.12)
- **Network Mode**: Bridged
- **PLMN**: 00101 (MCC=001, MNC=01) - Same as primary
- **TAC**: 7 - Same for handover compatibility
- **EARFCN**: 3600 (Band 7, ~2.66 GHz)
- **PCI**: 3 - Different for proper identification
- **Bandwidth**: 10 MHz

#### False Base Station (false)
- **IP**: DHCP assigned (typically 192.168.56.11)
- **Network Mode**: Bridged
- **PLMN**: Configurable (00101 default, 99970 for rogue)
- **TAC**: 7
- **EARFCN**: 3350 (Band 7, ~2.62 GHz)
- **PCI**: 2
- **Bandwidth**: 10 MHz

#### Open5GS Core Network (legitimate VM only)
- **MME IP**: 127.0.1.2
- **SGWC IP**: 127.0.0.3
- **SGWU IP**: 127.0.0.4
- **UPF IP**: 127.0.0.5
- **SMF IP**: 127.0.0.6
- **AMF IP**: 127.0.0.7

### Default Test Subscriber

Pre-configured during provisioning:
- **IMSI**: 001010000118896
- **Authentication Key (Ki)**: BD9044E60EFA8AD9052799E65D8AF224
- **OPc**: C86FD5618B748B85BBC6515C7AEDB9A4
- **Network Access Mode**: 2 (Packet and Circuit)
- **Subscriber Status**: 0 (Enabled)

## 🔧 Advanced Configuration

### Subscriber Management

```bash
# List subscribers
sudo subscriber.sh list

# Add new subscriber
sudo subscriber.sh add <imsi> <key> <opc>

# Delete all subscribers
sudo subscriber.sh delete-all

# Count subscribers
sudo subscriber.sh count
```

### Network Parameters

Edit configuration files in `/etc/srsran/legitimate/`:
- **enb_4g.conf**: Base station parameters
- **rr.conf**: Radio resource configuration
- **rb.conf**: Radio bearer configuration
- **sib.conf**: System information blocks

### Open5GS Parameters

Edit configuration files in `/etc/open5gs/`:
- **mme.yaml**: MME configuration
- **amf.yaml**: AMF configuration

## 🛠️ Troubleshooting

### SDR Device Issues

**Symptom**: `uhd_find_devices` shows no devices
**Solution**:
1. Check USB 3.0 ports (blue ports)
2. Verify VirtualBox Extension Pack
3. Manual USB attachment via VirtualBox menu

**Symptom**: Permission denied errors
**Solution**:
1. Check vboxusers group membership
2. Reboot host system
3. Check udev rules in VM

### Network Issues

**Symptom**: UE doesn't register
**Solutions**:
1. Verify subscriber credentials in SIM
2. Check signal strength (false BS should be stronger)
3. Verify PLMN configuration
4. Check Open5GS service status

**Symptom**: No IP connectivity
**Solutions**:
1. Check UPF service: `sudo systemctl status open5gs-upfd`
2. Check SMF service: `sudo systemctl status open5gs-smfd`
3. Verify UE APN configuration

### Service Issues

**Symptom**: Services not starting
**Solutions**:
1. Check MongoDB: `sudo systemctl status mongod`
2. Check Open5GS: `sudo systemctl status open5gs-mmed`
3. Check logs: `sudo journalctl -u open5gs-mmed -f`

### Provisioning Issues

**Symptom**: Provisioning fails
**Solutions**:
1. Check internet connectivity
2. Verify package repositories
3. Check available disk space
4. Re-provision: `vagrant provision legitimate`

## 📚 Reference Commands

### VM Management
```bash
./start.sh legitimate    # Start primary legitimate BS
./start.sh legitimate2   # Start secondary legitimate BS
./start.sh false         # Start false BS
./start.sh all          # Start all three VMs

./stop.sh legitimate     # Stop primary legitimate BS
./stop.sh legitimate2    # Stop secondary legitimate BS
./stop.sh false          # Stop false BS

./ssh.sh legitimate      # SSH into primary legitimate BS
./ssh.sh legitimate2     # SSH into secondary legitimate BS
./ssh.sh false           # SSH into false BS

./validate.sh            # Validate all installations
```

### Network Operations
```bash
# Start legitimate network
sudo srsenb /etc/srsran/legitimate/enb_4g.conf

# Monitor logs
sudo journalctl -u open5gs-mmed -f
sudo tail -f /var/log/open5gs/mme.log
```

### SDR Operations
```bash
# Check SDR devices
uhd_find_devices

# List USB devices
lsusb -t

# Check UHD version
uhd_find_devices --version
```

### Service Management
```bash
# Check all services
sudo systemctl status mongod
sudo systemctl status open5gs-mmed
sudo systemctl status open5gs-amfd

# Restart services
sudo systemctl restart open5gs-mmed
```

## 🔒 Security Considerations

### RF Isolation
- **MANDATORY**: Use Faraday cage for all testing
- **NEVER** operate outside controlled environment
- **MONITOR**: Ensure no legitimate network interference

### Data Protection
- Use test credentials only
- Never store real subscriber data
- Secure all configuration files

### Legal Compliance
- Obtain proper authorizations
- Document all activities
- Follow local regulations
- Report any unintended interference

## 📞 Support

### Getting Help
1. Check logs: `sudo journalctl -xe`
2. Validate setup: `./validate_setup.sh`
3. Check SDR: `uhd_find_devices`
4. Verify services: `sudo systemctl status`

### Common Issues
- **USB not detected**: Check Extension Pack and group membership
- **UE not registering**: Verify SIM programming and signal strength
- **Services failing**: Check MongoDB and network connectivity
- **Provisioning stuck**: Check internet and disk space

## 🎯 Next Steps

1. **Test legitimate network** with your UE
2. **Configure attack profiles** in false BS VM
3. **Implement attack scenarios** from attacks.md
4. **Document findings** and countermeasures

Remember: This environment is for **research and education only**. Always follow ethical and legal guidelines.
