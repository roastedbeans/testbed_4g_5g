# Legitimate Network Configuration Analysis for IMSI Catching

This document contains the analysis of the existing legitimate telecommunications setup used for IMSI catching security research.

## Network Overview

The legitimate setup consists of:
- **2 eNB cells** running srsRAN 4G
- **1 MME** running Open5GS
- **Dual-frequency deployment** (EARFCN 3600 and 3650)
- **Same PLMN** (MCC: 001, MNC: 01) across both cells

## Extracted Parameters

| Parameter | Cell 1 Value | Cell 2 Value |
|-----------|--------------|--------------|
| **PLMN** | | |
| MCC | 001 | 001 |
| MNC | 01 | 01 |
| **TAC** | 0x0007 | 0x0007 |
| **EARFCN** | 3600 | 3650 |
| **TX Gain** | 60 | 60 |
| **RX Gain** | 40 | 40 |
| **Cell ID** | 0x01 | 0x01 |
| **PCI** | 1 | 2 |
| **eNB ID** | 0x19B | 0x19C |
| **Bandwidth** | 50 PRB | 50 PRB |
| **MME Address** | 127.0.1.2 | 127.0.1.2 |
| **GTP Bind** | 127.0.1.10 | 127.0.1.11 |
| **S1C Bind** | 127.0.1.10 | 127.0.1.11 |

## Security Configuration

### MME Security Settings
- **Integrity algorithms**: EIA2, EIA1, EIA0 (ordered preference)
- **Ciphering algorithms**: EEA0, EEA1, EEA2 (ordered preference)
- **Network name**: "Open5GS"
- **Short name**: "Next"

## Cell Configuration Details

### Cell 1 (Primary)
- **Frequency**: EARFCN 3600
- **PCI**: 1 (used for physical layer identification)
- **TAC**: 7 (decimal)
- **Measurement reports**: Configured for A3 event (neighbor better than serving + 3dB offset)
- **Neighbor cell**: Cell 2 (ECI: 0x19C01, EARFCN: 3650, PCI: 2)

### Cell 2 (Secondary)
- **Frequency**: EARFCN 3650
- **PCI**: 2 (used for physical layer identification)
- **TAC**: 7 (decimal)
- **Measurement reports**: Configured for A3 event (neighbor better than serving + 6dB offset)
- **Neighbor cell**: Cell 1 (ECI: 0x19B01, EARFCN: 3600, PCI: 1)

## Inter-RAT Configuration

### UTRA (3G) Neighbors
- **FDD Carrier**: 9613 (UARFCN)
- **TDD Carrier**: 9505 (UARFCN)
- **Priority**: 6 (same as LTE)
- **Reselection thresholds**: High: 3dB, Low: 2dB

### GERAN (2G) Neighbors
- **ARFCN**: 871 (DCS1800 band)
- **Priority**: 0 (lower priority than LTE/UTRA)
- **NCC permitted**: 255 (all carriers allowed)
- **Reselection thresholds**: High: 2dB, Low: 2dB

## Radio Resource Configuration

### Common Parameters
- **RACH preambles**: 52
- **PRACH config**: Index 3, frequency offset 4
- **PDSCH power**: 0 dB relative to RS
- **Timer T300**: 2000ms (RRC connection setup)
- **Timer T301**: 100ms (RRC re-establishment)

### Scheduler Configuration
- **Policy**: Round-robin (time_rr)
- **MCS limits**: PDSCH max 28, PUSCH max 28
- **Aggregation levels**: 0-3
- **Control symbols**: 1-3

## Notes

- Both cells share the same MME (127.0.1.2)
- Handover is enabled between cells
- Inter-frequency measurements are configured
- 2G/3G fallback is available for legacy devices
- Security uses standard LTE algorithms (EIA2/EEA1 preferred)
