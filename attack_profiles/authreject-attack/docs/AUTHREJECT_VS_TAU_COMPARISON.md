# AuthReject Attack vs TAU Reject Attack: Technical Comparison

## Executive Summary

Both attacks are **Denial of Service (DoS)** techniques that prevent UEs from accessing cellular services, but they target **different stages** of the network connection lifecycle and have **different behavioral impacts** on the UE.

---

## Attack Definitions

### AuthReject (Authentication Rejection) Attack

**What it does:**
- Targets UEs during **initial network attachment (attach procedure)**
- Rejects authentication when UE first tries to connect to the network
- Exploits the **attach request → authentication → reject** sequence

**Trigger condition:**
- UE is in **EMM-DEREGISTERED** state
- UE attempts **initial attach** to network
- Or UE performs **combined attach** (LTE + voice)

**Result:**
- UE cannot establish **any** connection to the network
- UE shows "No Service" or "Emergency Calls Only"
- UE enters long backoff period (T3402 timer = 12 minutes)

---

### TAU Reject (Tracking Area Update Rejection) Attack

**What it does:**
- Targets UEs that are **already attached** to the network
- Rejects tracking area updates when UE moves to a new tracking area
- Exploits the **TAU request → reject** sequence

**Trigger condition:**
- UE is **already connected** (EMM-REGISTERED state)
- UE detects **TAC (Tracking Area Code) change**
- UE sends **Tracking Area Update Request**

**Result:**
- UE loses existing connection
- Forces UE to re-attach (if rejection cause is severe)
- May cause "Limited Service" or brief disconnection
- May enter backoff period (T3402 or T3411 depending on cause)

---

## Technical Comparison Table

| Aspect | AuthReject Attack | TAU Reject Attack |
|--------|-------------------|-------------------|
| **Attack Stage** | Initial attach procedure | After successful attach |
| **UE State** | EMM-DEREGISTERED | EMM-REGISTERED |
| **Target Procedure** | Attach Request | Tracking Area Update (TAU) |
| **NAS Message** | Attach Reject | TAU Reject |
| **Trigger** | TAC mismatch from idle state | TAC change while connected |
| **User Impact** | Complete loss of service | Connection drop + re-attach |
| **UE Shows** | "No Service" immediately | Brief disconnection, then retry |
| **Service Before Attack** | UE not connected | UE has active connection |
| **Backoff Timer** | T3402 (12 minutes) | T3411 (10s) or T3402 (12m) |
| **Emergency Calls** | May be blocked | Usually still available |
| **Recovery Method** | Wait 12 min or restart UE | Usually auto-recovers |
| **Persistence** | Long-term (12+ minutes) | Short-term (seconds to minutes) |
| **Stealthiness** | Medium (noticeable) | High (brief interruption) |

---

## Attack Flow Comparison

### AuthReject Attack Flow

```
Initial State: UE not connected (EMM-DEREGISTERED)
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 1. UE detects AuthReject cell (TAC 0x0008)             │
│    Signal: 70 dB > Legitimate 60 dB                    │
│    Status: Idle → Searching                            │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 2. UE initiates ATTACH PROCEDURE                       │
│    UE → BS: Attach Request (IMSI/GUTI)                 │
│    UE State: EMM-DEREGISTERED                          │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 3. AUTHENTICATION REJECTION                            │
│    BS → UE: Attach Reject                              │
│    Cause: #3 (Illegal UE) or #11 (PLMN not allowed)   │
│    Reason: IMSI not in HSS database                    │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 4. DENIAL OF SERVICE STATE                             │
│    UE State: EMM-DEREGISTERED                          │
│    UE Display: "No Service" / "Emergency Only"          │
│    T3402 Timer: Started (12 minutes)                   │
│    Behavior: Cannot retry attach until timer expires   │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 5. BACKOFF PERIOD (12 minutes)                         │
│    UE Status: Searching but avoiding PLMN 001/01       │
│    User Impact: No calls, no data, no SMS              │
│    Duration: 12+ minutes (or until UE restart)         │
└─────────────────────────────────────────────────────────┘
```

### TAU Reject Attack Flow

```
Initial State: UE connected to legitimate network (EMM-REGISTERED)
               Active data connection, calls working
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 1. UE detects TAU cell (different TAC)                 │
│    Current TAC: 0x0007 (legitimate)                    │
│    New TAC: 0x0008 (attack cell)                       │
│    Signal: 70 dB > Legitimate 60 dB                    │
│    UE Status: Connected → Handover/Reselection         │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 2. UE initiates TAU PROCEDURE                          │
│    UE → BS: Tracking Area Update Request (GUTI)        │
│    Type: Normal TAU (periodic or TAC change)           │
│    UE State: EMM-REGISTERED (still)                    │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 3. TAU REJECTION                                       │
│    BS → UE: TAU Reject                                 │
│    Cause: #11 (PLMN not allowed)                       │
│          #13 (Roaming not allowed)                     │
│          #15 (No suitable cells in TA)                 │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 4. CONNECTION DROP + FORCED RE-ATTACH                  │
│    UE State: EMM-REGISTERED → EMM-DEREGISTERED         │
│    Existing connection: Terminated                     │
│    UE Display: "Limited Service" (brief)               │
│    Behavior: Attempts to re-attach                     │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ 5. BACKOFF OR RETRY                                    │
│    If cause #11/13: T3402 timer (12 minutes)           │
│    If other causes: T3411 timer (10 seconds)           │
│    UE Status: Searches for other cells                 │
│    User Impact: Brief interruption → may recover       │
└─────────────────────────────────────────────────────────┘
```

---

## NAS Message Comparison

### AuthReject NAS Messages

```
UE → eNB: RRC Connection Request
         ↓
eNB → UE: RRC Connection Setup
         ↓
UE → eNB: RRC Connection Setup Complete
         ↓
UE → MME: ATTACH REQUEST
          ├─ Message Type: 0x41
          ├─ Attach Type: EPS attach (1)
          ├─ NAS Key Set ID: 0x07
          ├─ EPS Mobile Identity: IMSI (001010000000001)
          ├─ UE Network Capability: EEA0,EEA1,EEA2,EIA0,EIA1,EIA2
          └─ ESM Message Container: PDN Connectivity Request
         ↓
MME → UE: ATTACH REJECT
          ├─ Message Type: 0x44
          ├─ EMM Cause: #3 (Illegal UE)
          │            #11 (PLMN not allowed)
          │            #7 (EPS services not allowed)
          └─ ESM Message: (none)
         ↓
UE: Enters EMM-DEREGISTERED state
    Starts T3402 timer (12 minutes)
    Displays "No Service"
```

### TAU Reject NAS Messages

```
UE: Already in EMM-REGISTERED state
    Detects TAC change (0x0007 → 0x0008)
         ↓
UE → MME: TRACKING AREA UPDATE REQUEST
          ├─ Message Type: 0x48
          ├─ EPS Update Type: TA updating (0)
          ├─ NAS Key Set ID: 0x07
          ├─ Old GUTI: GUTI assigned by previous MME
          ├─ UE Network Capability: EEA0,EEA1,EEA2,EIA0,EIA1,EIA2
          ├─ Last Visited TAI: TAC=0x0007, PLMN=001/01
          └─ EPS Bearer Context Status: Active bearers
         ↓
MME → UE: TRACKING AREA UPDATE REJECT
          ├─ Message Type: 0x4B
          ├─ EMM Cause: #11 (PLMN not allowed)
          │            #13 (Roaming not allowed in this TA)
          │            #15 (No suitable cells in TA)
          │            #9 (UE identity cannot be derived)
          └─ T3446 Value: (optional backoff timer)
         ↓
UE: Releases existing connection
    Enters EMM-DEREGISTERED state
    Starts T3402 or T3411 timer (depends on cause)
    Attempts to find another cell
```

---

## Configuration Differences

### AuthReject Configuration

**Key Parameters:**
```yaml
# MME must reject ATTACH requests
tai:
  - plmn_id:
      mcc: 001
      mnc: 01
    tac: 8                    # Different from legitimate (7)

# HSS database must be EMPTY
# No subscribers provisioned → IMSI unknown → Attach Reject
```

**eNB Configuration:**
```conf
tac = 0x0008                  # Different TAC triggers attach
```

**Attack Type:** Passive (relies on empty HSS database)

---

### TAU Reject Configuration

**Key Parameters:**
```bash
# DoS profile configuration
SEND_TAU_REJECT=true
TAU_REJECT_CAUSE=11           # PLMN not allowed

# Can be combined with TAU loop
TAU_LOOP_ENABLED=true
CONSTANTLY_CHANGE_TAC=true
TAC_CHANGE_INTERVAL=10        # Change TAC every 10 seconds
```

**MME Configuration:**
```yaml
# MME must be configured to reject TAU
# May require source code modification or specific HSS state
```

**Attack Type:** Active (MME configured to reject TAU)

---

## User Experience Comparison

### AuthReject Attack (User Perspective)

**Timeline:**
```
T=0s    UE shows "Searching..."
T=5s    UE shows "No Service"
T=10s   User tries manual network search → 001/01 unavailable
T=30s   Still "No Service"
T=1m    User frustrated, checks SIM card
T=5m    Still no service
T=12m   T3402 expires, UE may retry
```

**What user notices:**
- ✗ Complete loss of service
- ✗ Cannot make calls (including emergency)
- ✗ Cannot send SMS
- ✗ No data connection
- ✗ Shows "Emergency Calls Only" or "No Service"
- ✗ Long duration (12+ minutes)
- ✗ Restart UE to recover faster

---

### TAU Reject Attack (User Perspective)

**Timeline:**
```
T=0s    UE connected, browsing web normally
T=5s    Brief "Loading..." on app
T=10s   "No internet connection" briefly
T=15s   Connection restored (UE re-attached to legitimate cell)
```

**What user notices:**
- ⚠ Brief interruption (5-30 seconds)
- ⚠ May drop active call
- ⚠ Data session interrupted
- ⚠ Quick recovery if legitimate cell available
- ✓ Less noticeable than AuthReject
- ✓ Auto-recovery in most cases

---

## Attack Effectiveness Comparison

| Metric | AuthReject | TAU Reject |
|--------|------------|------------|
| **Impact Severity** | High (complete DoS) | Medium (temporary disruption) |
| **Duration** | Long (12+ minutes) | Short (seconds to minutes) |
| **User Awareness** | High (very obvious) | Low (brief glitch) |
| **Recovery** | Difficult (long backoff) | Easy (auto-retry) |
| **Stealth** | Low (obvious attack) | High (seems like network issue) |
| **Repeatability** | Requires 12-min wait | Can repeat frequently |
| **Defense Difficulty** | Easy (detect TAC anomaly) | Hard (normal TAU behavior) |
| **Emergency Services** | Affected | Usually unaffected |
| **Setup Complexity** | Low (passive) | Medium (active rejection) |
| **Legal Risk** | Very High | Very High |

---

## When Each Attack Is Used

### AuthReject Attack Best For:

1. **Complete service denial** - Target cannot access network at all
2. **Long-term disruption** - Keep target offline for 12+ minutes
3. **Initial connection blocking** - Prevent new attachments
4. **Demonstrating attach procedure vulnerabilities**
5. **Research on authentication security**

### TAU Reject Attack Best For:

1. **Disrupting active connections** - Drop ongoing calls/sessions
2. **Stealthy service degradation** - Less obvious to user
3. **Mobility-based attacks** - Target users moving between areas
4. **TAU loop attacks** - Drain battery via repeated TAU
5. **Research on mobility management vulnerabilities**

---

## Combined Attack Strategy

The two attacks can be combined for maximum effect:

```
Strategy: TAU Loop + AuthReject
┌─────────────────────────────────────────────────────────┐
│ Phase 1: TAU LOOP                                       │
│   - Constantly change TAC (every 10 seconds)            │
│   - Force UE to send repeated TAU requests              │
│   - Drain battery, cause frustration                    │
│   Duration: 2-5 minutes                                 │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ Phase 2: TAU REJECT                                     │
│   - Send TAU Reject with cause #11                      │
│   - Force UE to deregister                              │
│   - UE attempts to re-attach                            │
└─────────────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────────────┐
│ Phase 3: AUTHREJECT                                     │
│   - UE sends Attach Request                             │
│   - Send Attach Reject (IMSI not in HSS)               │
│   - UE enters 12-minute backoff                         │
│   Result: Complete DoS                                  │
└─────────────────────────────────────────────────────────┘
```

---

## Defense and Detection

### Detecting AuthReject Attack

**On UE side:**
- Repeated attach rejections from same PLMN
- TAC anomalies (unusual TAC values)
- Stronger-than-normal signal from unknown cell
- Immediate rejection after attach attempt

**On Network side:**
- Unauthorized S1AP connections
- Invalid TAC in attach requests
- Unusual rejection patterns
- Rogue base station RF signatures

### Detecting TAU Reject Attack

**On UE side:**
- Repeated TAU rejections
- Constantly changing TAC
- Unexpected deregistration
- Battery drain from frequent TAU

**On Network side:**
- High TAU rejection rate
- TAC oscillation patterns
- Legitimate UEs losing service
- RF interference reports

---

## 3GPP Standards Reference

### AuthReject References

- **3GPP TS 24.301 Section 5.5.1.2.5**: Attach procedure - Attach reject by network
- **3GPP TS 24.008 Annex G**: EMM cause codes
  - #3: Illegal UE
  - #6: Illegal ME
  - #11: PLMN not allowed
  - #12: Location area not allowed
  - #13: Roaming not allowed in this location area

### TAU Reject References

- **3GPP TS 24.301 Section 5.5.3.2.5**: Tracking area updating procedure - Reject by network
- **3GPP TS 24.301 Section 5.5.3.3**: Abnormal cases in tracking area updating
- **EMM Cause Codes for TAU Reject:**
  - #9: UE identity cannot be derived by the network
  - #10: Implicitly detached
  - #11: PLMN not allowed
  - #13: Roaming not allowed in this tracking area
  - #15: No suitable cells in tracking area

---

## Summary: Quick Reference

**Choose AuthReject Attack if:**
- ✓ Target UE is not connected
- ✓ Need complete service denial
- ✓ Want long-duration DoS (12+ minutes)
- ✓ Testing initial attach security

**Choose TAU Reject Attack if:**
- ✓ Target UE is already connected
- ✓ Need to drop active connections
- ✓ Want stealthy disruption
- ✓ Testing mobility management security
- ✓ Want repeatable short disruptions

**Key Difference:**
> **AuthReject** = Prevent initial network attachment (UE can't connect)
> **TAU Reject** = Disrupt existing connection (UE drops connection)

---

## Legal and Ethical Warnings

⚠️ **Both attacks are ILLEGAL without authorization**

- Violate telecommunications laws worldwide
- Can affect emergency services (911/112)
- Carry severe criminal penalties
- May cause harm or property damage
- Subject to FCC/equivalent regulatory action

**Authorized use only:**
- Shielded research environments
- Proper licensing and approvals
- Institutional oversight
- Educational purposes with safeguards

---

**Document Version:** 1.0
**Last Updated:** October 2024
**Purpose:** Educational comparison for security research
