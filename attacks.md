# False Base Station Attack Scenarios

Detailed technical documentation of attack vectors, methodologies, and countermeasures for cellular network security research.

## ⚠️ Ethical and Legal Notice

**THIS DOCUMENT IS FOR EDUCATIONAL AND RESEARCH PURPOSES ONLY**

All attack scenarios described here are **ILLEGAL** when performed without authorization. This information is provided to:

1. **Security researchers** conducting authorized research
2. **Network operators** understanding threats to their infrastructure
3. **Developers** building more secure systems
4. **Educators** teaching cellular network security

Unauthorized use may result in severe criminal penalties including imprisonment and fines.

---

## Attack Overview

### Attack Classification

| Attack Type | Severity | Complexity | Detection Difficulty |
|-------------|----------|------------|---------------------|
| IMSI Catcher | HIGH | Medium | Medium |
| Downgrade | HIGH | Low | Low |
| MITM | CRITICAL | High | Medium-High |
| DoS | MEDIUM | Low | Easy |

### Prerequisites

All attacks require:
1. False base station with higher signal strength than legitimate BS
2. UE within range of false BS
3. Matching or compatible PLMN configuration
4. RF-isolated environment

---

## Attack Scenario 1: IMSI Catcher

### Overview

IMSI (International Mobile Subscriber Identity) catchers, also known as "Stingrays" or "cell-site simulators," capture subscriber identities by impersonating a legitimate base station.

### Attack Methodology

#### Phase 1: Initialization

```bash
# Configure false BS for IMSI catching
sudo attack_config.sh set imsi_catcher
sudo start_false_bs.sh -d 15
```

**Configuration Changes:**
- Security algorithms: `EEA0, EIA0` (no encryption)
- Identity request: Enabled for all UEs
- Attach accept: Delayed to ensure capture

#### Phase 2: UE Attraction

The false BS operates with **higher signal strength** (80 dB vs 65 dB), causing the UE to:

1. Detect stronger cell
2. Initiate cell reselection
3. Attempt attach to false BS

#### Phase 3: Identity Capture

When UE attaches, false BS:

1. **Sends Identity Request** (NAS message)
   - Type: IMSI
   - Additional: IMEI, IMEISV

2. **UE Responds** with:
   - IMSI: Permanent subscriber identifier
   - IMEI: Device identifier
   - IMEISV: Device version

3. **Logs Captured Data**:
   ```json
   {
     "timestamp": "2025-10-10 14:23:45",
     "imsi": "001010123456789",
     "imei": "351234567890123",
     "imeisv": "3512345678901234",
     "lac": "0x0007",
     "cell_id": "0x01"
   }
   ```

#### Phase 4: Optional Actions

**Option A: Reject Attach**
- Send Attach Reject
- UE returns to legitimate BS
- Identity captured

**Option B: Silent Disconnect**
- Drop connection without response
- UE searches for another cell
- Less suspicious to user

**Option C: Relay to Core** (Advanced)
- Forward to legitimate core
- Maintain connection
- Enables longer-term MITM

### Technical Details

#### NAS Messages Involved

```
UE → False BS: Attach Request
               ↓
False BS → UE: Identity Request (IMSI)
               ↓
UE → False BS: Identity Response (IMSI=001010123456789)
               ↓
False BS → UE: Identity Request (IMEI)
               ↓
UE → False BS: Identity Response (IMEI=351234567890123)
               ↓
False BS → UE: Attach Accept OR Attach Reject
```

#### Captured Data Fields

- **IMSI**: 15 digits, format: MCC(3) + MNC(2-3) + MSIN(9-10)
- **TMSI**: Temporary identifier (if previously assigned)
- **IMEI**: 15 digits device identifier
- **IMEISV**: 16 digits with software version
- **LAI**: Location Area Identity
- **TAI**: Tracking Area Identity

### Detection Methods

**For UE/Users:**
- Sudden network disconnection after brief connection
- Increased battery drain from frequent reattachment
- Inability to complete calls
- Network name changes (if different PLMN)

**For Network Operators:**
- Unexpected S1AP/NGAP connection attempts
- Invalid authentication attempts
- Unusual paging patterns
- RF interference reports

### Countermeasures

**Technical:**
1. **IMSI Encryption** (SUCI in 5G)
   - 5G uses public key encryption for IMSI
   - Prevents plaintext IMSI capture

2. **Base Station Authentication**
   - Mutual authentication (5G)
   - Verify base station legitimacy

3. **SIM-based Protection**
   - Use SIMs supporting IMSI encryption
   - Regular TMSI updates

**Operational:**
- Monitor for rogue base stations
- Use spectrum analysis tools
- Deploy IMSI catcher detectors
- User awareness training

**Regulatory:**
- Strict licensing requirements
- Heavy penalties for unauthorized use
- Equipment tracking and control

### Real-World Usage

**Legitimate Applications:**
- Law enforcement (with warrant)
- Emergency services (locating missing persons)
- Military operations
- Network testing (isolated environments)

**Known Incidents:**
- Government surveillance programs
- Criminal usage for fraud
- Journalist/activist tracking
- Corporate espionage

---

## Attack Scenario 2: Downgrade Attack

### Overview

Downgrade attacks force UEs to use weak or no encryption, allowing traffic interception and decryption.

### Attack Methodology

#### Phase 1: Algorithm Negotiation Manipulation

```bash
# Configure for downgrade attack
sudo attack_config.sh set downgrade
sudo start_false_bs.sh
```

**Configuration:**
```conf
# Prioritize weak algorithms
EEA_PREFERENCE_ORDER="EEA0, EEA1"  # Avoid EEA2 (strongest)
EIA_PREFERENCE_ORDER="EIA0, EIA1"  # Avoid EIA2 (strongest)
```

#### Phase 2: Security Mode Command

When UE attaches, false BS sends Security Mode Command with:

```
NAS Security Algorithms:
- Encryption: EEA0 (null cipher) OR EEA1 (SNOW 3G - weaker)
- Integrity: EIA1 (SNOW 3G) - minimum needed for attach
```

#### Phase 3: UE Acceptance

Most UEs will accept the downgrade because:
1. Algorithm is within their supported list
2. No minimum encryption requirements enforced
3. Prioritize connectivity over security

#### Phase 4: Traffic Capture

With weakened/disabled encryption:
- Capture all NAS messages in plaintext
- Intercept user plane traffic
- Decode using known algorithms

### Algorithm Comparison

| Algorithm | Type | Strength | Speed | Decrypt Difficulty |
|-----------|------|----------|-------|-------------------|
| EEA0 | None | None | N/A | Trivial (plaintext) |
| EEA1 | SNOW 3G | Medium | Fast | Moderate |
| EEA2 | AES-128 | Strong | Medium | Very High |
| NEA0 (5G) | None | None | N/A | Trivial |
| NEA1 (5G) | SNOW 3G | Medium | Fast | Moderate |
| NEA2 (5G) | AES-128 | Strong | Medium | Very High |
| NEA3 (5G) | ZUC | Strong | Fast | Very High |

### Security Mode Command Example

```
Security Mode Command:
├── Message Type: 0x5D
├── Selected NAS Security Algorithms:
│   ├── Encryption: EEA0 (000)
│   └── Integrity: EIA1 (001)
├── NAS Key Set Identifier: 0x07
└── Replayed UE Security Capabilities
```

### Detection & Prevention

**Detection Methods:**
- Monitor negotiated security algorithms
- Alert on EEA0/NEA0 usage
- Log all downgrade events
- Statistical analysis of encryption usage

**Prevention:**
1. **UE-side:**
   - Enforce minimum encryption (EEA2/NEA2)
   - Reject EEA0/NEA0
   - Alert user on weak encryption

2. **Network-side:**
   - Never offer weak algorithms
   - Mandatory strong encryption policies
   - Detect and block rogue base stations

3. **Standards:**
   - 5G mandates stronger baseline security
   - Deprecate weak algorithms
   - Improve algorithm negotiation

---

## Attack Scenario 3: Man-in-the-Middle (MITM)

### Overview

MITM attacks allow the attacker to intercept, inspect, and potentially modify traffic between UE and legitimate core network.

### Attack Methodology

#### Architecture

```
UE ←→ False BS ←→ [Attacker Tools] ←→ Legitimate Core Network
         ↓                                     ↓
    Capture & Inspect                    Normal Operation
```

#### Phase 1: Establish Connection

```bash
# Configure MITM mode
sudo attack_config.sh set mitm
# Edit /opt/attack_profiles/mitm.conf:
#   MITM_MODE="passive"  # or "active" for modification
#   RELAY_TO_REAL_CORE=true
#   REAL_CORE_MME_IP="192.168.56.10"
```

#### Phase 2: Relay Configuration

False BS acts as transparent proxy:

**Control Plane (S1AP/NGAP):**
```
UE NAS Messages → False BS → Inspect → Forward to MME/AMF
Core Responses ← False BS ← Inspect ← From MME/AMF
```

**User Plane (GTP-U):**
```
UE Data → False BS → DPI → Forward to SGW/UPF
Internet ← False BS ← DPI ← From SGW/UPF
```

#### Phase 3: Traffic Analysis

**Captured Information:**
- All NAS messages (if EEA0)
- DNS queries
- HTTP traffic
- TLS handshakes (metadata)
- Application protocols
- Timing information

**Deep Packet Inspection:**
```bash
# Example captured data
DNS Query: www.example.com → 93.184.216.34
HTTP GET /page.html
User-Agent: Mozilla/5.0...
Cookies: session=abc123...
```

#### Phase 4: Active Manipulation (Optional)

If `MITM_MODE="active"`:
- Modify DNS responses (redirect to attacker sites)
- Inject HTTP content
- Strip HTTPS redirects
- Modify API responses

### Traffic Inspection Tools

**PCAP Capture:**
```bash
# All traffic
tcpdump -i any -w /tmp/mitm_full.pcap

# NAS only
tcpdump -i any 'sctp' -w /tmp/nas_only.pcap

# User plane
tcpdump -i ogstun -w /tmp/user_plane.pcap
```

**Real-time Analysis:**
```bash
# Monitor HTTP
sudo tcpdump -i ogstun -A 'tcp port 80'

# DNS queries
sudo tcpdump -i ogstun 'udp port 53'
```

### Security Implications

**Privacy Violations:**
- Complete loss of communication privacy
- Location tracking
- Behavioral profiling
- Metadata collection

**Security Risks:**
- Credential theft (if cleartext/weak encryption)
- Session hijacking
- Malware injection
- Phishing attacks

### Countermeasures

**End-to-End Encryption:**
- HTTPS everywhere
- VPN usage
- Encrypted messaging (Signal, WhatsApp)
- Certificate pinning

**Network Security:**
- Mutual authentication
- Perfect forward secrecy
- End-to-end integrity checks
- Anomaly detection

---

## Attack Scenario 4: Denial of Service (DoS)

### Overview

DoS attacks prevent UEs from accessing network services by disrupting their connection attempts or established sessions.

### Attack Methodologies

#### Method 1: Attach Rejection

**Configuration:**
```bash
sudo attack_config.sh set dos
# Set: DOS_TECHNIQUE="reject_attach"
```

**Behavior:**
- Accept RRC Connection Request
- Receive Attach Request
- Send **Attach Reject** with cause code
- UE blocked from network

**Cause Codes:**
- `#7`: GPRS services not allowed
- `#11`: PLMN not allowed
- `#12`: Location area not allowed
- `#13`: Roaming not allowed

#### Method 2: Silent Drop

**Behavior:**
- Accept connection
- Never respond to Attach Request
- UE timeout and retry
- Repeated failures drain battery

#### Method 3: Resource Exhaustion

**False BS side:**
- Accept maximum connections
- Never release resources
- Exhaust own capacity
- Block legitimate users

**UE side:**
- Create excessive bearers
- Trigger repeated re-authentications
- Flood with paging messages
- Drain UE battery and CPU

#### Method 4: Jamming

**Continuous transmission:**
- Transmit on cellular frequencies
- Prevent UE from detecting legitimate BS
- Effective but easily detected

### Impact Assessment

| Method | User Impact | Detection | Resource Cost | Legal Risk |
|--------|-------------|-----------|---------------|------------|
| Attach Reject | High | Easy | Low | Very High |
| Silent Drop | Medium | Medium | Low | Very High |
| Resource Exhaustion | Variable | Hard | High | Very High |
| Jamming | Critical | Very Easy | Low | Extreme |

### Emergency Service Implications

**CRITICAL**: DoS attacks can prevent emergency calls (911/112), which may result in:
- Loss of life
- Severe criminal penalties
- Civil liability
- Federal prosecution

### Countermeasures

**Network Protection:**
- Rogue BS detection systems
- Spectrum monitoring
- Automatic blacklisting
- Redundant coverage (multiple bands/operators)

**UE Protection:**
- Automatic fallback to other cells
- Emergency call prioritization
- Anomaly detection
- User alerts

---

## Comparative Analysis

### Attack Effectiveness Matrix

| Attack | Data Capture | Stealth | Duration | User Impact |
|--------|--------------|---------|----------|-------------|
| IMSI Catcher | IMSI, IMEI | Medium | Seconds | Low |
| Downgrade | All traffic | High | Hours | Low-Medium |
| MITM | Complete | Medium-High | Hours | Low |
| DoS | None | Low | Variable | High |

### Skill & Resource Requirements

| Attack | Technical Skill | Equipment Cost | Setup Time | Risk Level |
|--------|----------------|----------------|------------|------------|
| IMSI Catcher | Medium | $1K-$5K | Hours | HIGH |
| Downgrade | Medium | $1K-$5K | Hours | HIGH |
| MITM | High | $2K-$10K | Days | VERY HIGH |
| DoS | Low | $500-$2K | Hours | EXTREME |

---

## Legal Framework

### United States

**Relevant Laws:**
- **18 U.S.C. § 1029**: Fraud with access devices
- **18 U.S.C. § 2511**: Wiretapping
- **47 U.S.C. § 301**: Unauthorized radio transmission
- **47 U.S.C. § 333**: Interference with communications

**Penalties:**
- Up to 20 years imprisonment
- Fines up to $250,000 per violation
- Equipment forfeiture
- FCC violations (up to $10M+ per violation)

### European Union

**GDPR Considerations:**
- Unauthorized data collection
- Privacy violations
- Severe fines (up to 4% of global revenue)

**National Laws:**
- Telecommunications Act violations
- Criminal surveillance laws
- National security provisions

### International

Most countries have similar or stricter prohibitions. Always consult local legal counsel.

---

## Authorized Research Guidelines

### Institutional Requirements

1. **IRB Approval** (Institutional Review Board)
2. **Legal Review** by institutional counsel
3. **RF Licensing** from regulatory authority
4. **Insurance** for liability coverage

### Technical Requirements

1. **RF Shielding**
   - Faraday cage or RF-shielded room
   - Verified isolation from external environment
   - Documented effectiveness testing

2. **Power Limits**
   - Minimum necessary TX power
   - Attenuators in place
   - Monitoring equipment

3. **Safety Protocols**
   - Emergency shutdown procedures
   - Continuous monitoring
   - Incident response plan

### Documentation

- Detailed experiment logs
- Configuration records
- Data handling procedures
- Destruction/retention policies

---

## Conclusion

False base station attacks represent serious threats to cellular network security and user privacy. Understanding these attacks is crucial for:

- **Researchers**: Developing countermeasures
- **Operators**: Protecting infrastructure
- **Users**: Understanding risks
- **Regulators**: Creating effective policies

**Always remember:** These techniques are powerful and dangerous. Use responsibly, legally, and ethically.

---

## References

1. 3GPP TS 33.401 - Security architecture (LTE)
2. 3GPP TS 33.501 - Security architecture (5G)
3. "Practical Attacks Against Privacy and Availability in 4G/LTE Mobile Communication Systems"
4. "Breaking LTE on Layer Two"
5. "LTEInspector: A Systematic Approach for Adversarial Testing of 4G LTE"
6. NIST Guidelines on Cellular Network Security

---

**Last Updated**: October 2025
**Document Version**: 1.0
**Classification**: Educational/Research Only

