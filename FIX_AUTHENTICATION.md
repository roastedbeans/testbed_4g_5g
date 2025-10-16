# Authentication Failure Fix Guide

## Problem Analysis

Your logs show:
```
[emm] WARNING: Authentication failure (../src/mme/emm-sm.c:1143)
[emm] WARNING: IMSI[001010000118896] OGS_NAS_EMM_CAUSE[20]
[emm] WARNING: Authentication failure(MAC failure)
```

**This means**: The authentication keys in your SIM card don't match the subscriber database.

## Solution Steps

### Step 1: Verify Subscriber in Database

SSH into the legitimate VM and check if subscriber exists:

```bash
./ssh.sh legitimate
sudo subscriber.sh list
```

**Expected output**: Should show `001010000118896`

If not shown, add it:
```bash
sudo subscriber.sh add 001010000118896 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA
```

### Step 2: Verify Subscriber Keys in MongoDB

Check the exact keys stored in the database:

```bash
# Inside legitimate VM
mongosh --quiet --eval "
db = db.getSiblingDB('open5gs');
db.subscribers.find({imsi: '001010000118896'}, {imsi:1, 'security.k':1, 'security.opc':1}).pretty();
"
```

**Expected output**:
```json
{
  "_id": ObjectId("..."),
  "imsi": "001010000118896",
  "security": {
    "k": "465B5CE8B199B49FAA5F0A2EE238A6BC",
    "opc": "E8ED289DEBA952E4283B54E88E6183CA"
  }
}
```

### Step 3: Match Your SIM Card Programming

**Your SIM card MUST have these EXACT values:**

| Parameter | Value |
|-----------|-------|
| **IMSI** | `001010000118896` |
| **Ki (K)** | `465B5CE8B199B49FAA5F0A2EE238A6BC` |
| **OPc** | `E8ED289DEBA952E4283B54E88E6183CA` |
| **AMF** | `8000` |

### Step 4: Reprogram Your SIM Card

Use your SIM card programming tool (e.g., pySim, SysmoUSIM-SJS1, etc.) to program the SIM with the correct values.

**Example using pySim:**
```bash
# Format depends on your SIM programmer
pysim-prog.py \
  --imsi 001010000118896 \
  --ki 465B5CE8B199B49FAA5F0A2EE238A6BC \
  --opc E8ED289DEBA952E4283B54E88E6183CA \
  --mcc 001 \
  --mnc 01
```

### Step 5: Alternative - Update Database to Match SIM

If you already have a programmed SIM and want to use those keys instead, update the database:

```bash
# Inside legitimate VM
# Replace K_VALUE and OPC_VALUE with your SIM's actual keys

mongosh --quiet --eval "
db = db.getSiblingDB('open5gs');
db.subscribers.updateOne(
  { imsi: '001010000118896' },
  { \$set: {
      'security.k': 'YOUR_SIM_K_VALUE',
      'security.opc': 'YOUR_SIM_OPC_VALUE'
  }}
);
"
```

### Step 6: Restart Open5GS Services

After updating the database:

```bash
# Inside legitimate VM
sudo systemctl restart open5gs-mmed
sudo systemctl restart open5gs-amfd
sudo systemctl restart open5gs-hssd  # If exists

# Verify services are running
sudo systemctl status open5gs-mmed
```

### Step 7: Test Connection Again

1. Turn off your UE completely
2. Wait 10 seconds
3. Turn on your UE
4. Monitor the logs:

```bash
# Inside legitimate VM
sudo tail -f /var/log/open5gs/mme.log
```

## Expected Successful Connection Logs

After fixing, you should see:
```
[mme] INFO: InitialUEMessage
[mme] INFO: [001010000118896] Unknown UE by IMSI
[emm] INFO: [] Attach request
[emm] INFO:     IMSI[001010000118896]
[mme] INFO: [001010000118896] Attach complete
[mme] INFO: EMM State Changed [State:DEREGISTERED]
```

**NO** authentication failure or MAC failure warnings.

## Troubleshooting

### Issue: Subscriber not in database
```bash
sudo subscriber.sh add 001010000118896 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA
```

### Issue: MongoDB not responding
```bash
sudo systemctl status mongod
sudo systemctl restart mongod
```

### Issue: Keys are correct but still failing
1. Check MCC/MNC match: Should be 001/01
2. Verify TAC is 7 in both eNB and MME configs
3. Check PLMN configuration:
   ```bash
   grep -r "mcc.*001" /etc/srsran/legitimate/
   grep -r "mnc.*01" /etc/srsran/legitimate/
   ```

### Issue: SIM card programming failed
- Verify your SIM card is programmable (not locked)
- Use correct SIM card programmer software
- Check SIM card reader connection
- Try a different blank SIM card

## Quick Fix Script

Run this inside the legitimate VM:

```bash
#!/bin/bash
# Quick authentication fix

# Delete existing subscriber
mongosh --quiet --eval "
db = db.getSiblingDB('open5gs');
db.subscribers.deleteOne({imsi: '001010000118896'});
"

# Add with correct keys
sudo subscriber.sh add 001010000118896 465B5CE8B199B49FAA5F0A2EE238A6BC E8ED289DEBA952E4283B54E88E6183CA

# Restart services
sudo systemctl restart open5gs-mmed
sudo systemctl restart open5gs-amfd

echo "✅ Subscriber re-added with correct keys"
echo "Now reprogram your SIM card with:"
echo "  IMSI: 001010000118896"
echo "  K:    465B5CE8B199B49FAA5F0A2EE238A6BC"
echo "  OPC:  E8ED289DEBA952E4283B54E88E6183CA"
```

## Common Mistakes

1. ❌ **Using OP instead of OPc** - Make sure you use OPc, not OP
2. ❌ **Wrong key format** - Keys should be 32 hex characters (128 bits)
3. ❌ **Case sensitivity** - Use uppercase hex for consistency
4. ❌ **Mismatched IMSI** - IMSI must match exactly
5. ❌ **Wrong MCC/MNC** - Must be 001/01 to match PLMN

## Key Concepts

- **K (Ki)**: Secret authentication key (128-bit)
- **OPc**: Derived operator key (128-bit, derived from OP)
- **MAC failure**: Message Authentication Code mismatch
- **PLMN**: Public Land Mobile Network (MCC + MNC)

The MAC failure means the UE calculated a different authentication response than the network expected, which happens when the keys don't match.
