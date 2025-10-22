# Handover Simulation Guide - Dual Legitimate Base Stations

## Overview

This guide explains how to simulate and test **UE handover** between two legitimate base stations running on the same VM using dual SDR devices when devices are in close proximity.

## Prerequisites

### Hardware Setup
- ✅ **2 SDR devices** connected to legitimate VM
- ✅ **VMs running** (legitimate with dual BS, false)
- ✅ **UE (phone/modem)** with SIM programmed for IMSI 001010000118896
- ✅ **Antennas positioned** for controlled signal testing

### Network Configuration
- ✅ **legitimate BS #1**: EARFCN 3450, PCI 1, TX gain ~65dB (SDR #1)
- ✅ **legitimate BS #2**: EARFCN 3600, PCI 3, TX gain ~65dB (SDR #2)
- ✅ **Shared PLMN**: 00101 (MCC=001, MNC=01)
- ✅ **Same TAC**: 7 (for handover compatibility)
- ✅ **Different PCI**: 1 vs 3 (for BS identification)

## VM Configuration Reference

### Network Architecture Overview

```
legitimate VM (192.168.56.10)
├── Open5GS Core Network (MME, HSS, etc.)
├── srsRAN eNodeB #1 (enb_id: 0x19B) - SDR #1
├── srsRAN eNodeB #2 (enb_id: 0x19D) - SDR #2
├── Configs: open5gs/ + srsran/legitimate/ + srsran/legitimate2/
├── SDR #1 (LibreSDR B220) - BS #1
├── SDR #2 (LibreSDR B220) - BS #2
├── Frequency BS #1: 885.0 MHz (Band 8)
└── Frequency BS #2: 895.0 MHz (Band 8)

false VM (192.168.56.11)
├── srsRAN eNodeB (enb_id: 0x19C)
├── Standalone attack mode
├── Configs: attack_profiles/ + srsran/
├── SDR #3 (LibreSDR B220)
└── Frequency: 905.0 MHz (Band 8)
```

### Detailed Configuration Mapping

#### **legitimate VM - Primary Base Station**

| **Component** | **Parameter** | **Value** | **Purpose** |
|---------------|---------------|-----------|-------------|
| **VM Network** | IP Address | 192.168.56.10 | Core network host |
| | Hostname | legitimate-bs | VM identification |
| **Open5GS Core** | MME Address | 0.0.0.0:36412 | Accepts remote connections |
| | GTP-C Address | 0.0.0.0 | Accepts remote GTP |
| | PLMN | 001/01 | MCC=001, MNC=01 |
| | TAC | 7 | Tracking area for handover |
| | Config Files | open5gs/ | Core network configs only |
| **srsRAN eNodeB** | enb_id | 0x19B (411) | Unique BS identifier |
| | MCC/MNC | 001/01 | Same as core network |
| | TAC | 0x0007 | Same as core network |
| | PCI | 1 | Physical cell ID |
| | EARFCN | 3450 | 885.0 MHz (Band 8) |
| | TX Gain | 60 dB | Default transmit power |
| | RX Gain | 40 dB | Default receive gain |
| | MME Address | 127.0.1.2 | Local core connection |
| | Config Files | srsran/ | Radio access network configs |
| **RF Hardware** | Device | LibreSDR B220 #1 | SDR hardware |
| | Antenna | Band 8 (900 MHz) | Frequency-specific antenna |
| | USB Controller | xHCI (USB 3.0) | High-speed USB |

#### **legitimate2 VM - Secondary Base Station**

| **Component** | **Parameter** | **Value** | **Purpose** |
|---------------|---------------|-----------|-------------|
| **VM Network** | IP Address | 192.168.56.12 | Secondary BS |
| | Hostname | legitimate-bs2 | VM identification |
| **Open5GS Core** | Status | NOT INSTALLED | Uses shared core |
| | Components | None | No Open5GS files present |
| **srsRAN eNodeB** | enb_id | 0x19D (413) | Unique BS identifier |
| | MCC/MNC | 001/01 | Same PLMN as legitimate |
| | TAC | 0x0007 | Same TAC for handover |
| | PCI | 3 | Different from legitimate |
| | EARFCN | 3550 | 895.0 MHz (Band 8) |
| | TX Gain | 60 dB | Default transmit power |
| | RX Gain | 40 dB | Default receive gain |
| | MME Address | 192.168.56.10:36412 | Remote core connection |
| | GTP Bind Addr | 192.168.56.12 | Local GTP binding |
| | S1C Bind Addr | 192.168.56.12 | Local S1AP binding |
| | Config Files | srsran/ | Radio access network configs |
| **RF Hardware** | Device | LibreSDR B220 #2 | SDR hardware |
| | Antenna | Band 8 (900 MHz) | Frequency-specific antenna |
| | USB Controller | xHCI (USB 3.0) | High-speed USB |

#### **false VM - Attack Base Station**

| **Component** | **Parameter** | **Value** | **Purpose** |
|---------------|---------------|-----------|-------------|
| **VM Network** | IP Address | 192.168.56.11 | Attack BS |
| | Hostname | false-bs | VM identification |
| **Open5GS Core** | Status | NOT INSTALLED | Standalone operation |
| | MME Connection | None | No core network |
| **srsRAN eNodeB** | enb_id | 0x19C (412) | Unique BS identifier |
| | MCC/MNC | 001/01 | Mimics legitimate PLMN |
| | TAC | 0x0007 | Same as legitimate |
| | PCI | 4 | Different from others |
| | EARFCN | 3650 | 905.0 MHz (Band 8) |
| | TX Gain | 80 dB | Higher for attack (override) |
| | RX Gain | 40 dB | Default receive gain |
| | MME Address | 127.0.1.2 | Local (no actual connection) |
| | Config Files | srsran/ | Standard radio configs |
| **Attack Modes** | IMSI Catcher | ENABLED | Capture subscriber IDs |
| | MITM | ENABLED | Intercept traffic |
| | DoS | ENABLED | Disrupt service |
| | Downgrade | ENABLED | Force weak encryption |
| | Config Files | attack_profiles/ | Attack-specific overrides |
| **RF Hardware** | Device | LibreSDR B220 #3 | SDR hardware |
| | Antenna | Band 8 (900 MHz) | Frequency-specific antenna |
| | USB Controller | xHCI (USB 3.0) | High-speed USB |

### Frequency and Cell Planning

#### **Band 8 (900 MHz) Frequency Allocation**

| **Base Station** | **EARFCN** | **Frequency** | **Channel Spacing** |
|------------------|------------|---------------|-------------------|
| legitimate | 3450 | 885.0 MHz | Baseline |
| legitimate2 | 3550 | 895.0 MHz | +10 MHz |
| false | 3650 | 905.0 MHz | +20 MHz from baseline |

#### **Physical Cell ID (PCI) Allocation**

| **Base Station** | **PCI** | **Purpose** |
|------------------|---------|-------------|
| legitimate | 1 | Primary cell |
| legitimate2 | 3 | Secondary cell |
| false | 4 | Attack cell |

#### **eNodeB ID Allocation**

| **Base Station** | **enb_id (hex)** | **enb_id (dec)** | **ECI Range** |
|------------------|------------------|------------------|---------------|
| legitimate | 0x19B | 411 | 0x19B01 - 0x19BFF |
| legitimate2 | 0x19D | 413 | 0x19D01 - 0x19DFF |
| false | 0x19C | 412 | 0x19C01 - 0x19CFF |

*ECI = eNodeB ID × 256 + Cell ID*

### Measurement and Handover Configuration

#### **Neighbor Cell Measurements**

**legitimate VM measures:**
- legitimate2: ECI=0x19D01, EARFCN=3550, PCI=3
- false: ECI=0x19C01, EARFCN=3650, PCI=4

**legitimate2 VM measures:**
- legitimate: ECI=0x19B01, EARFCN=3450, PCI=1
- false: ECI=0x19C01, EARFCN=3650, PCI=4

**false VM measures:**
- None (standalone attack mode)

#### **Handover Event Configuration**

```bash
# Event A3: Neighbor becomes stronger than serving cell
eventA = 3
a3_offset = 6;              # 6dB threshold
hysteresis = 0;             # No hysteresis
time_to_trigger = 480;      # 480ms delay
trigger_quant = "RSRP";     # RSRP-based triggering
max_report_cells = 1;       # Report strongest neighbor
report_interv = 120;        # 120ms reporting interval
report_amount = 1;          # One report
```

#### **Signal Quality Thresholds**

```bash
rsrp_config = 4;   # RSRP averaging coefficient
rsrq_config = 4;   # RSRQ averaging coefficient
```

### Core Network Sharing Configuration

#### **legitimate VM (Core Network Host)**
- **IP Address**: 192.168.56.10
- **Open5GS MME**: Active on 0.0.0.0:36412 (accepts remote connections)
- **GTP-C Server**: Active on 0.0.0.0 (accepts remote GTP)
- **srsRAN eNodeB**: Connects to MME at 127.0.1.2 (localhost)
- **Subscriber DB**: MongoDB with IMSI 001010000118896
- **Role**: Full core network + radio access network

#### **legitimate2 VM (Shared Network Client)**
- **IP Address**: 192.168.56.12
- **Open5GS Status**: NOT INSTALLED (uses shared MME)
- **srsRAN eNodeB**: Connects to MME at 192.168.56.10:36412 (legitimate VM)
- **GTP/S1AP Binding**: 192.168.56.12 (local interfaces)
- **Role**: Radio access network only (eNodeB client)

#### **false VM (Attack Mode - Standalone)**
- **IP Address**: 192.168.56.11
- **Open5GS Status**: NOT INSTALLED
- **srsRAN eNodeB**: Configured for 127.0.1.2 (no real MME connection)
- **Role**: Standalone attack operations

#### **Network Connectivity Requirements**
- **Bridged Network**: All VMs on 192.168.56.0/24 subnet
- **MME Reachability**: legitimate2 must reach legitimate at 192.168.56.10
- **Firewall Rules**: Allow S1AP (port 36412) and GTP-U (port 2152) traffic
- **DHCP Assignment**: IPs assigned by host network DHCP server

#### **Shared Subscriber Database**
- **Location**: legitimate VM MongoDB instance
- **IMSI**: 001010000118896
- **Ki**: BD9044E60EFA8AD9052799E65D8AF224
- **OPc**: C86FD5618B748B85BBC6515C7AEDB9A4
- **Access Method**: Both legitimate BS access via shared MME
- **Synchronization**: Automatic through core network

## Handover Theory

### Why Handover Works with Close Devices

Even with devices in close proximity, handover can be simulated by:

1. **Signal Strength Manipulation**: Adjust TX gain to make one BS appear stronger
2. **Frequency Separation**: Different EARFCN values (3450 vs 3600)
3. **Physical Cell ID Difference**: PCI 1 vs PCI 3
4. **Network Measurements**: UE continuously measures signal quality

### Handover Triggers

The UE will handover when:
- **Stronger signal detected** on different frequency/PCI
- **Current signal degrades** below threshold
- **Better network quality** available
- **Load balancing** requirements

## Step-by-Step Handover Simulation

### Step 1: Start Base Stations

```bash
# Terminal 1: Start legitimate BS (includes core network)
./ssh.sh legitimate
sudo srsenb /etc/srsran/legitimate/enb_4g.conf

# Terminal 2: Start legitimate2 BS (connects to shared core)
./ssh.sh legitimate2
sudo srsenb /etc/srsran/legitimate/enb_4g.conf

# Terminal 3: Monitor core network logs
./ssh.sh legitimate
sudo tail -f /var/log/open5gs/mme.log
```

### Step 2: Initial UE Connection

1. **Power on UE** with programmed SIM
2. **UE connects** to legitimate BS (EARFCN 3450, PCI 1)
3. **Verify connection** in MME logs:
   ```
   [mme] INFO: InitialUEMessage
   [emm] INFO: Attach request
   [emm] INFO: IMSI[001010000118896]
   ```

### Step 3: Monitor Signal Strengths

```bash
# Check initial signal levels
./ssh.sh legitimate -c "sudo /vagrant/shared/utils/signal_manager.sh get_tx_gain"
./ssh.sh legitimate2 -c "sudo /vagrant/shared/utils/signal_manager.sh get_tx_gain"

# Both should show ~65 dB initially
```

### Step 4: Trigger Handover (Method 1: Signal Degradation)

#### Reduce legitimate BS Signal
```bash
# Gradually reduce legitimate BS signal strength
./ssh.sh legitimate -c "sudo /vagrant/shared/utils/signal_manager.sh set_tx_gain 50"
```

#### Increase legitimate2 BS Signal
```bash
# Increase legitimate2 BS signal strength
./ssh.sh legitimate2 -c "sudo /vagrant/shared/utils/signal_manager.sh set_tx_gain 75"
```

### Step 5: Monitor Handover Process

#### Watch Core Network Logs
```bash
# In legitimate VM terminal
sudo tail -f /var/log/open5gs/mme.log
```

**Successful Handover Indicators:**
```
[mme] INFO: Handover Required
[mme] INFO: Handover Request (Source: legitimate, Target: legitimate2)
[mme] INFO: Handover Command sent
[mme] INFO: Handover Complete
[emm] INFO: UE Context transferred to legitimate2
```

#### Monitor Handover Events
```bash
# Start handover monitoring
./ssh.sh legitimate -c "sudo /vagrant/shared/utils/monitor_handover.sh"
./ssh.sh legitimate2 -c "sudo /vagrant/shared/utils/monitor_handover.sh"
```

### Step 6: Verify Handover Success

#### Check UE Connection Status
- UE should show **same network** but **different cell info**
- Signal bars should remain stable
- Data connectivity should continue uninterrupted

#### Verify Network Parameters
```bash
# Check which BS the UE is connected to
./ssh.sh legitimate -c "sudo /vagrant/shared/utils/monitor_handover.sh"
# Look for "UE connected to legitimate" or "Handover to legitimate2"

./ssh.sh legitimate2 -c "sudo /vagrant/shared/utils/monitor_handover.sh"
# Look for "UE connected to legitimate2" or "Handover from legitimate"
```

## Alternative Handover Methods

### Method 2: Physical Movement (If Possible)

1. **Position UE** closer to legitimate BS initially
2. **Move UE** toward legitimate2 BS antenna
3. **Monitor** automatic handover as signal strengths change

### Method 3: Antenna Isolation

1. **Use directional antennas** pointed away from each other
2. **Position UE** in overlap zone
3. **Adjust antenna directions** to create signal gradients
4. **Trigger handover** by changing antenna orientations

### Method 4: Frequency-Based Trigger

1. **Use RF shielding** between UE and legitimate BS
2. **Expose UE** to legitimate2 BS signal
3. **UE detects** stronger signal on different frequency
4. **Automatic handover** occurs

## Handover Monitoring Tools

### Signal Strength Monitoring
```bash
# Real-time signal monitoring
./ssh.sh legitimate -c "watch -n1 'sudo /vagrant/shared/utils/signal_manager.sh get_tx_gain'"
./ssh.sh legitimate2 -c "watch -n1 'sudo /vagrant/shared/utils/signal_manager.sh get_tx_gain'"
```

### UE Connection Status
```bash
# Check connected UEs on each BS
./ssh.sh legitimate -c "sudo /vagrant/shared/utils/monitor_handover.sh"
./ssh.sh legitimate2 -c "sudo /vagrant/shared/utils/monitor_handover.sh"
```

### Network Traffic Analysis
```bash
# Monitor handover signaling
./ssh.sh legitimate -c "sudo tail -f /var/log/open5gs/mme.log | grep -i handover"

# Check RRC connection events
./ssh.sh legitimate -c "sudo journalctl -u open5gs-mmed -f | grep -i handover"
```

## Troubleshooting Handover Issues

### Issue: Handover Not Triggering

**Check Signal Difference:**
```bash
# Ensure sufficient signal difference (>5-10 dB)
legit_signal=$(./ssh.sh legitimate -c "sudo /vagrant/shared/utils/signal_manager.sh get_tx_gain")
legit2_signal=$(./ssh.sh legitimate2 -c "sudo /vagrant/shared/utils/signal_manager.sh get_tx_gain")
echo "Signal difference: $((legit2_signal - legit_signal)) dB"
```

**Fix:** Increase signal difference to 15-20 dB

### Issue: UE Stays on Same BS

**Check PCI Difference:**
```bash
# Ensure different PCI values
./ssh.sh legitimate -c "grep pci /etc/srsran/legitimate/rr.conf"  # Should be 1
./ssh.sh legitimate2 -c "grep pci /etc/srsran/legitimate/rr.conf"  # Should be 3
```

**Check EARFCN Difference:**
```bash
# Ensure different frequencies
./ssh.sh legitimate -c "grep dl_earfcn /etc/srsran/legitimate/rr.conf"  # Should be 3450
./ssh.sh legitimate2 -c "grep dl_earfcn /etc/srsran/legitimate/rr.conf"  # Should be 3600
```

### Issue: Handover Fails

**Check TAC Consistency:**
```bash
# Both should have TAC=7
./ssh.sh legitimate -c "grep tac /etc/srsran/legitimate/rr.conf"
./ssh.sh legitimate2 -c "grep tac /etc/srsran/legitimate/rr.conf"
```

**Check Core Network Connectivity:**
```bash
# legitimate2 should connect to legitimate's MME
./ssh.sh legitimate2 -c "ping -c3 192.168.56.10"  # legitimate VM IP
```

## Advanced Handover Scenarios

### Scenario 1: Ping-Pong Handover Testing
```bash
# Alternate signal strengths rapidly
while true; do
  ./ssh.sh legitimate -c "sudo /vagrant/shared/utils/signal_manager.sh set_tx_gain 75"
  ./ssh.sh legitimate2 -c "sudo /vagrant/shared/utils/signal_manager.sh set_tx_gain 50"
  sleep 30
  
  ./ssh.sh legitimate -c "sudo /vagrant/shared/utils/signal_manager.sh set_tx_gain 50"
  ./ssh.sh legitimate2 -c "sudo /vagrant/shared/utils/signal_manager.sh set_tx_gain 75"
  sleep 30
done
```

### Scenario 2: Load Balancing Simulation
```bash
# Simulate network load by starting data transfers
# Adjust signals to balance load between BS
```

### Scenario 3: Signal Quality Testing
```bash
# Gradually degrade signal quality
# Monitor handover trigger points
# Test different handover thresholds
```

## Success Criteria

✅ **UE connects to legitimate BS initially**
✅ **Signal adjustment triggers measurement reports**
✅ **Handover decision made by network**
✅ **Handover command sent to UE**
✅ **UE switches to legitimate2 BS**
✅ **Connection remains stable**
✅ **No service interruption**
✅ **Core network logs show successful handover**

## Key Takeaways

1. **Signal strength difference** of 15-20 dB typically triggers handover
2. **Different EARFCN values** allow frequency-based cell selection
3. **Unique PCI values** enable proper cell identification
4. **Same TAC and PLMN** ensure handover compatibility
5. **Core network coordination** manages the handover process

## Related Documentation

- `README.md` - Project overview and architecture
- `setup.md` - Complete setup instructions
- `attacks.md` - Attack scenario documentation

**Handover simulation demonstrates LTE network mobility and cell selection algorithms in a controlled research environment!**
