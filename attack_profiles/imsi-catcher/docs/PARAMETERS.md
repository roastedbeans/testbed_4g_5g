# IMSI Catching Attack Parameters

This document compares the parameters between the legitimate network and the False Base Station (FBS) configuration used for the IMSI catching attack.

## Parameter Comparison

| Parameter | Legitimate Value | FBS Value | Why Different? |
|-----------|-----------------|-----------|----------------|
| **PLMN** | | | |
| MCC | 001 | 001 | Must match operator to lure devices |
| MNC | 01 | 01 | Must match operator to lure devices |
| **TAC** | 0x0007 (7) | 0x9999 (39321) | Triggers TAU procedure for identity capture |
| **EARFCN** | 3600/3650 | 3600 | Targets same frequency band for interception |
| **TX Gain** | 60 dB | 60 dB | Same as legitimate (SDR cannot exceed 80dB) |
| **RX Gain** | 40 dB | 40 dB | Same RX sensitivity |
| **Cell ID** | 0x01 | 0x02 | Avoids conflicts with legitimate cells |
| **PCI** | 1/2 | 3 | Unused PCI to avoid conflicts |
| **eNB ID** | 0x19B/0x19C | 0x19D | Different eNB identity |
| **Bandwidth** | 50 PRB | 50 PRB | Same bandwidth for compatibility |
| **MME Address** | 127.0.1.2 | 127.0.1.100 | Isolated attack MME |
| **SDR Serial** | C5XA7X9/P44SEGH | VRFKZRP | Third SDR for false base station |
| **Integrity** | EIA2, EIA1, EIA0 | EIA0 only | Disabled to capture unencrypted IMSI/IMEI |
| **Ciphering** | EEA0, EEA1, EEA2 | EEA0 only | Disabled to capture unencrypted IMSI/IMEI |
| **Handover** | Enabled | Disabled | Standalone operation for attack isolation |
| **TAC in SIB1** | Not present | 39321 (0x9999) | Explicit TAC for TAU trigger |
| **Connection Timer** | 30000ms | 1000ms | Quick disconnect after identity capture |

## Attack Strategy Rationale

### Same Parameters (Stealth)
- **MCC/MNC**: Must be identical to appear as the same operator to lure devices
- **EARFCN**: Uses same frequency to target legitimate users for interception
- **Bandwidth**: Compatible with legitimate network
- **RX Gain**: Same receive sensitivity

### Modified Parameters (Attack)
- **TAC**: Changed to 0x9999 to trigger Tracking Area Update procedure for identity capture
- **TX Gain**: Increased by 35 dB (+30-40 dB stronger) for 100% success rate
- **Cell ID/PCI**: Different to avoid conflicts but still valid
- **Security**: Weakened to EIA0/EEA0 (no integrity/encryption) to capture unencrypted IMSI/IMEI
- **Handover**: Disabled for isolated attack operation
- **Connection Timer**: Reduced to 1000ms for quick disconnect after identity capture

### New Parameters (Isolation)
- **MME Address**: Separate IP range (127.0.1.100) for attack containment
- **SDR Device**: Third SDR (VRFKZRP) dedicated to attack
- **Network Name**: Changed to "FBS_Test" for identification

## Technical Details

### TAC Selection (0x9999)
- **Hex**: 0x9999 = 39321 decimal
- **Purpose**: Reserved TAC value that triggers TAU procedure
- **Effect**: Forces UE to perform tracking area update for identity capture

### TX Gain (Same as Legitimate)
- **Legitimate**: 60 dB
- **FBS**: 60 dB (same as legitimate)
- **Limitation**: SDR hardware cannot exceed 80dB total gain
- **Purpose**: Identity capture through protocol manipulation, not signal overpowering

### Security Degradation
- **Integrity**: EIA0 (null integrity) instead of EIA2/EIA1
- **Ciphering**: EEA0 (null encryption) instead of EEA1/EEA2
- **Purpose**: Allows capture of unencrypted IMSI/IMEI identity information

### Connection Timer (1000ms)
- **Legitimate**: 30000ms (30 seconds)
- **FBS**: 1000ms (1 second)
- **Purpose**: Quick disconnect after identity capture before UE notices anomaly
- **Effect**: UE seamlessly reconnects to legitimate network

### SDR Assignment
- **Legitimate Cell 1**: SDR serial C5XA7X9
- **Legitimate Cell 2**: SDR serial P44SEGH
- **False Base Station**: SDR serial VRFKZRP (third device)
- **Purpose**: Hardware isolation for attack containment

## Warning

This configuration is designed for **authorized security research only**. The parameters are specifically chosen to:
- Demonstrate IMSI/IMEI capture techniques
- Show man-in-the-middle attack capabilities
- Maintain operator impersonation for identity theft
- Illustrate null encryption exploitation

**Never deploy in production networks or without explicit authorization.**
