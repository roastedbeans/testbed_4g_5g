# Handover Verification Guide

This guide explains how to verify that handover works between the legitimate base stations.

## Architecture Overview

The handover setup consists of:
- **legitimate VM**: Runs Open5GS core network (MME) + srsRAN ENB
- **legitimate2 VM**: Runs srsRAN ENB only (connects to MME in legitimate VM)

## Configuration Changes Made

### 1. MME Configuration (legitimate/configs/open5gs/mme.yaml)
- S1AP server listens on `127.0.1.2` (for local ENB) and `0.0.0.0` (for remote ENBs)
- GTP-C server listens on `127.0.0.2` (for local ENB) and `0.0.0.0` (for remote ENBs)
- This allows the MME to be accessible from other VMs for handover

### 2. ENB Configurations
- **legitimate ENB**: Connects to MME at `127.0.1.2` (localhost)
- **legitimate2 ENB**: Connects to MME at detected IP of legitimate VM

### 3. Dynamic IP Configuration
- Added `configure_mme_ip.sh` script to automatically detect and configure MME IP
- Updated provision scripts to include MME IP configuration step

## Verification Steps

### Step 1: Start the Core Network
```bash
# Start legitimate VM first (with MME)
vagrant up legitimate
vagrant ssh legitimate

# Start Open5GS MME
sudo systemctl start open5gs-mmed
sudo systemctl status open5gs-mmed
```

### Step 2: Start First Base Station
```bash
# In legitimate VM, start the ENB
sudo srsenb /etc/srsran/legitimate/enb_4g.conf
```

### Step 3: Configure and Start Second Base Station
```bash
# Start legitimate2 VM
vagrant up legitimate2
vagrant ssh legitimate2

# Configure MME IP address
/vagrant/shared/utils/configure_mme_ip.sh legitimate /etc/srsran/legitimate/enb_4g.conf

# Start the second ENB
sudo srsenb /etc/srsran/legitimate/enb_4g.conf
```

### Step 4: Verify Connections
```bash
# Check MME logs for S1AP connections from both ENBs
vagrant ssh legitimate
sudo tail -f /var/log/open5gs/mme.log

# Look for messages like:
# "S1AP connection established" from both ENB IDs (0x19B and 0x19D)
```

### Step 5: Test Handover
```bash
# Use a mobile device or UE simulator to connect
# Monitor handover between the two base stations

# Check handover logs
/vagrant/shared/utils/monitor_handover.sh
```

## Expected Behavior

1. **MME Accessibility**: MME should accept connections from both local (127.0.1.2) and remote ENBs
2. **ENB Registration**: Both ENBs should successfully register with the MME
3. **Handover Signaling**: X2 interface should be established between ENBs for handover
4. **UE Mobility**: Mobile devices should be able to handover between the two base stations

## Troubleshooting

### MME Connection Issues
```bash
# Check if MME is listening on correct ports
sudo netstat -tuln | grep :36412  # S1AP
sudo netstat -tuln | grep :2123   # GTP-C
```

### ENB Connection Issues
```bash
# Check ENB logs for connection errors
tail -f /tmp/enb.log

# Verify MME IP configuration
grep "mme_addr" /etc/srsran/legitimate/enb_4g.conf
```

### Network Connectivity
```bash
# Test connectivity between VMs
ping <legitimate-vm-ip>

# Check firewall rules
sudo ufw status
```

## Key Files Modified

- `legitimate/configs/open5gs/mme.yaml` - MME server addresses
- `legitimate2/configs/srsran/enb.conf` - MME IP configuration
- `shared/utils/configure_mme_ip.sh` - Dynamic IP configuration script
- `legitimate2/provision.sh` - Updated provisioning instructions
- `legitimate2/Vagrantfile` - Updated startup instructions

## Next Steps

1. Test the complete handover scenario with real SDR hardware
2. Implement X2 interface configuration for direct ENB-to-ENB handover
3. Add handover monitoring and logging improvements
4. Consider implementing measurement-based handover triggers
