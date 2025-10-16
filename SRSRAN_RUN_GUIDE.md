# srsRAN Execution Guide

## Prerequisites

### 1. Start VMs
```bash
# Start legitimate base station first
./start.sh legitimate

# Then start false base station  
./start.sh false
```

### 2. Attach SDR Devices
```bash
# Attach SDR to legitimate VM
./sdr_attach.sh legitimate

# Attach SDR to false VM
./sdr_attach.sh false
```

### 3. Verify SDR Setup
```bash
# SSH into VMs and check SDR
./ssh.sh legitimate
uhd_find_devices  # Should show device
uhd_usrp_probe --args="type=b200"  # Should work
exit

./ssh.sh false  
uhd_find_devices  # Should show device
uhd_usrp_probe --args="type=b200"  # Should work
exit
```

## Running srsRAN Base Stations

### Legitimate Base Station (4G LTE)

#### Method 1: Direct Command
```bash
# SSH into legitimate VM
./ssh.sh legitimate

# Start legitimate 4G LTE network
sudo srsenb /etc/srsran/legitimate/enb_4g.conf
```

#### Method 2: Using the Configuration Script
```bash
# SSH into legitimate VM
./ssh.sh legitimate

# Run the configuration setup (if needed)
sudo /vagrant/legitimate/scripts/setup_network.sh

# Start the network
sudo srsenb /etc/srsran/legitimate/enb_4g.conf
```

### False Base Station (Attack Scenarios)

#### Method 1: Using Attack Scripts
```bash
# SSH into false VM
./ssh.sh false

# Configure attack mode (choose one):
sudo /vagrant/false/scripts/attack_config.sh set imsi_catcher
# OR
sudo /vagrant/false/scripts/attack_config.sh set mitm
# OR  
sudo /vagrant/false/scripts/attack_config.sh set dos

# Start false base station
sudo /vagrant/false/scripts/start_false_bs.sh
```

#### Method 2: Direct Commands

**IMSI Catcher Mode:**
```bash
# SSH into false VM
./ssh.sh false

# Start with attack profile configuration
sudo srsenb /vagrant/false/configs/attack_profiles/enb_4g_rogue.conf
```

**Standard False BS Mode:**
```bash
# SSH into false VM  
./ssh.sh false

# Start with default false BS configuration
sudo srsenb /etc/srsran/false/enb.conf
```

## Testing and Verification

### 1. Check Network Status
```bash
# In legitimate VM
sudo systemctl status open5gs-mmed  # Should be active
sudo systemctl status open5gs-amfd  # Should be active (if 5G)
```

### 2. Monitor Logs
```bash
# Legitimate BS logs
sudo journalctl -u open5gs-mmed -f

# srsRAN logs (in another terminal)
# The srsenb command will show real-time logs
```

### 3. Test UE Connection
```bash
# Program your test SIM with:
# IMSI: 001010000118896
# K: 465B5CE8B199B49FAA5F0A2EE238A6BC
# OPC: E8ED289DEBA952E4283B54E88E6183CA

# Insert SIM into test UE (phone/modem)
# UE should automatically connect to legitimate BS
# Then test handover to false BS
```

## Attack Scenarios

### IMSI Catcher Attack
```bash
# Configure attack
./ssh.sh false
sudo /vagrant/false/scripts/attack_config.sh set imsi_catcher

# Start attack
sudo /vagrant/false/scripts/start_false_bs.sh

# Monitor captured IMSIs
tail -f /tmp/imsi_captures.log
```

### Man-in-the-Middle Attack
```bash
# Configure attack
./ssh.sh false
sudo /vagrant/false/scripts/attack_config.sh set mitm

# Start attack
sudo /vagrant/false/scripts/start_false_bs.sh

# Monitor intercepted traffic
tail -f /tmp/mitm_capture.pcap
```

### Denial of Service Attack
```bash
# Configure attack
./ssh.sh false
sudo /vagrant/false/scripts/attack_config.sh set dos

# Start attack  
sudo /vagrant/false/scripts/start_false_bs.sh

# Monitor DoS effects
tail -f /tmp/dos_attack.log
```

## Signal Management

### Adjust TX/RX Gain
```bash
# SSH into either VM
./ssh.sh legitimate  # or ./ssh.sh false

# Interactive signal adjustment
sudo /vagrant/shared/utils/adjust_signal.sh

# Or direct commands
sudo /vagrant/shared/utils/signal_manager.sh set_tx_gain 80
sudo /vagrant/shared/utils/signal_manager.sh set_rx_gain 40
```

### Monitor Handover
```bash
# Monitor UE handovers between BS
sudo /vagrant/shared/utils/monitor_handover.sh
```

## Stopping srsRAN

### Stop Base Stations
```bash
# Press Ctrl+C in the terminal running srsenb
# Or kill the process
sudo pkill srsenb
```

### Stop VMs
```bash
# Stop false BS first
./stop.sh false

# Then stop legitimate BS
./stop.sh legitimate
```

## Troubleshooting

### SDR Device Issues
```bash
# Check device detection
uhd_find_devices

# Check permissions
ls -la /dev/bus/usb/* | grep 2500

# Reattach device
sudo udevadm control --reload-rules
sudo udevadm trigger
```

### Network Issues
```bash
# Check Open5GS services
sudo systemctl status open5gs-mmed
sudo systemctl status open5gs-amfd

# Check MongoDB
sudo systemctl status mongod

# View detailed logs
sudo journalctl -u open5gs-mmed -n 50
```

### UE Connection Issues
```bash
# Verify subscriber exists
sudo /usr/local/bin/subscriber.sh list

# Check SIM programming matches:
# IMSI: 001010000118896
# K: 465B5CE8B199B49FAA5F0A2EE238A6BC  
# OPC: E8ED289DEBA952E4283B54E88E6183CA
```

## Performance Tips

1. **Start legitimate BS first** before false BS
2. **Use higher TX gain on false BS** (80 dB vs 65 dB) for handover demos
3. **Monitor system resources** - srsRAN is CPU intensive
4. **Use dedicated SDR devices** - one per VM
5. **Ensure RF isolation** for real attack testing

## Quick Start Commands

```bash
# Complete setup and test
./start.sh legitimate && ./start.sh false
./sdr_attach.sh legitimate && ./sdr_attach.sh false
./ssh.sh legitimate -c "sudo srsenb /etc/srsran/legitimate/enb_4g.conf"
# (in another terminal)
./ssh.sh false -c "sudo /vagrant/false/scripts/start_false_bs.sh"
```
