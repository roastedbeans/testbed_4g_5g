# AuthReject Attack Parameters

This document compares the parameters between the legitimate network and the Authentication Rejection (AuthReject) attack configuration used for DoS attacks.

## Parameter Comparison

| Parameter | Legitimate Value | AuthReject Value | Why Different? |
|-----------|------------------|------------------|----------------|
| **PLMN** | | | |
| MCC | 001 | 001 | Must match operator to appear legitimate |
| MNC | 01 | 01 | Must match operator to appear legitimate |
| **TAC** | 0x0007 (7) | 0x0008 (8) | Triggers authentication procedure causing rejection |
| **EARFCN** | 3600/3650 | 3600 | Targets same frequency band for interference |
| **TX Gain** | 60 dB | 70 dB | +10 dB stronger signal to attract UEs |
| **RX Gain** | 40 dB | 40 dB | Same RX sensitivity |
| **Cell ID** | 0x01 | 0x03 | Avoids conflicts with legitimate cells |
| **PCI** | 1/2 | 4 | Unused PCI to avoid conflicts |
| **eNB ID** | 0x19B/0x19C | 0x19E | Different eNB identity |
| **Bandwidth** | 50 PRB | 50 PRB | Same bandwidth for compatibility |
| **MME Address** | 127.0.1.2 | 127.0.1.2 | Same as legitimate (attacks run separately) |
| **Integrity** | EIA2, EIA1, EIA0 | EIA0 | Disabled for attack (no integrity protection) |
| **Ciphering** | EEA0, EEA1, EEA2 | EEA0 | Disabled for attack (no encryption) |
| **Handover** | Enabled | Disabled | Standalone operation |
| **Network Name** | "Open5GS" | "AuthReject_Test" | Identification for testing |
| **HSS Database** | Contains provisioned UEs | Empty (no subscribers) | Forces "IMSI unknown" rejection |

## Attack Strategy Rationale

### Same Parameters (Stealth)
- **MCC/MNC**: Must be identical to appear as the same operator
- **EARFCN**: Uses same frequency to target legitimate users
- **Bandwidth**: Compatible with legitimate network
- **RX Gain**: Same receive sensitivity

### Modified Parameters (Attack)
- **TAC**: Changed to 0x0008 to trigger authentication procedure
- **TX Gain**: Increased by 10 dB to attract UEs away from legitimate network
- **Cell ID/PCI**: Different to avoid conflicts but still valid
- **Security**: Weakened to EIA0/EEA0 (no integrity/encryption)
- **Handover**: Disabled for isolated attack operation

### New Parameters (Isolation)
- **MME Address**: Same as legitimate (attacks run at different times)
- **Network Name**: Changed to "AuthReject_Test" for identification
- **Attach/Auth Rejection**: Enabled to cause DoS by rejecting connections

## Technical Details

### TAC Selection (0x0008)
- **Hex**: 0x0008 = 8 decimal
- **Purpose**: Different TAC triggers UE authentication procedure
- **Effect**: Forces UE to attempt authentication with attack MME

### TX Gain Increase (+10 dB)
- **Legitimate**: 60 dB
- **AuthReject**: 70 dB (+10 dB stronger)
- **Purpose**: Signal overpowering for UE capture
- **Safety**: Requires careful power management in lab environment

### Authentication Rejection Mechanism
- **HSS Database**: Kept empty or target IMSI removed
- **MME Behavior**: Rejects attach/auth with "IMSI unknown in HSS"
- **Purpose**: Creates denial of service by preventing UE connections
- **Effect**: UEs cannot establish service through the attack network
- **Implementation**: Use `sudo open5gs-dbctl remove <IMSI>` or keep HSS empty

### Security Degradation
- **Integrity**: EIA0 (null integrity) instead of EIA2/EIA1
- **Ciphering**: EEA0 (null encryption) instead of EEA1/EEA2
- **Purpose**: Forces rejection of authentication attempts

### Network Configuration
- **MME Address**: Same as legitimate (attacks run at different times)
- **eNB Address**: Compatible with legitimate network
- **Purpose**: Simplified configuration for sequential testing

## Warning

This configuration is designed for **authorized security research only**. The parameters are specifically chosen to:
- Demonstrate authentication rejection DoS attack techniques
- Force UE connection failures
- Maintain operator impersonation capabilities

**Never deploy in production networks or without explicit authorization.**
