# FBS Downgrade Attack Parameters

This document compares the parameters between the legitimate network and the False Base Station (FBS) configuration used for the downgrade attack.

## Parameter Comparison

| Parameter | Legitimate Value | FBS Value | Why Different? |
|-----------|-----------------|-----------|----------------|
| **PLMN** | | | |
| MCC | 001 | 001 | Must match operator to appear legitimate |
| MNC | 01 | 01 | Must match operator to appear legitimate |
| **TAC** | 0x0007 (7) | 0x9999 (39321) | Triggers TAU procedure causing downgrade |
| **EARFCN** | 3600/3650 | 3600 | Targets same frequency band for interference |
| **TX Gain** | 60 dB | 75 dB | +15 dB stronger signal to override legitimate |
| **RX Gain** | 40 dB | 40 dB | Same RX sensitivity |
| **Cell ID** | 0x01 | 0x02 | Avoids conflicts with legitimate cells |
| **PCI** | 1/2 | 3 | Unused PCI to avoid conflicts |
| **eNB ID** | 0x19B/0x19C | 0x19D | Different eNB identity |
| **Bandwidth** | 50 PRB | 50 PRB | Same bandwidth for compatibility |
| **MME Address** | 127.0.1.2 | 127.0.1.100 | Isolated attack MME |
| **SDR Serial** | C5XA7X9/P44SEGH | VRFKZRP | Third SDR for false base station |
| **Integrity** | EIA2, EIA1, EIA0 | EIA0 only | Disabled for attack (no integrity protection) |
| **Ciphering** | EEA0, EEA1, EEA2 | EEA0 only | Disabled for attack (no encryption) |
| **Handover** | Enabled | Disabled | Standalone operation |
| **TAC in SIB1** | Not present | 39321 (0x9999) | Explicit TAC for TAU trigger |

## Attack Strategy Rationale

### Same Parameters (Stealth)
- **MCC/MNC**: Must be identical to appear as the same operator
- **EARFCN**: Uses same frequency to target legitimate users
- **Bandwidth**: Compatible with legitimate network
- **RX Gain**: Same receive sensitivity

### Modified Parameters (Attack)
- **TAC**: Changed to 0x9999 to trigger Tracking Area Update procedure
- **TX Gain**: Increased by 15 dB to overpower legitimate signal
- **Cell ID/PCI**: Different to avoid conflicts but still valid
- **Security**: Weakened to EIA0/EEA0 (no integrity/encryption)
- **Handover**: Disabled for isolated attack operation

### New Parameters (Isolation)
- **MME Address**: Separate IP range (127.0.1.100) for attack containment
- **SDR Device**: Third SDR (VRFKZRP) dedicated to attack
- **Network Name**: Changed to "FBS_Test" for identification

## Technical Details

### TAC Selection (0x9999)
- **Hex**: 0x9999 = 39321 decimal
- **Purpose**: Reserved TAC value that triggers TAU reject
- **Effect**: Forces UE to search for alternative networks (2G/3G)

### TX Gain Increase (+15 dB)
- **Legitimate**: 60 dB
- **FBS**: 75 dB (+15 dB stronger)
- **Purpose**: Signal overpowering for UE capture
- **Safety**: Requires careful power management in lab environment

### Security Degradation
- **Integrity**: EIA0 (null integrity) instead of EIA2/EIA1
- **Ciphering**: EEA0 (null encryption) instead of EEA1/EEA2
- **Purpose**: Forces UE downgrade to weaker 2G security (A5/0)

### SDR Assignment
- **Legitimate Cell 1**: SDR serial C5XA7X9
- **Legitimate Cell 2**: SDR serial P44SEGH
- **False Base Station**: SDR serial VRFKZRP (third device)
- **Purpose**: Hardware isolation for attack containment

## Warning

This configuration is designed for **authorized security research only**. The parameters are specifically chosen to:
- Demonstrate LTE downgrade attack techniques
- Force UE fallback to insecure 2G networks
- Maintain operator impersonation capabilities

**Never deploy in production networks or without explicit authorization.**
