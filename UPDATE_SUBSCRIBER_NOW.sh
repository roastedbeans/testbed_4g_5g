#!/bin/bash
# Emergency Subscriber Update Script
# Run this inside the legitimate VM to update subscriber keys

echo "🔄 Updating subscriber keys to match SIM card..."
echo ""
echo "SIM Card Credentials:"
echo "  IMSI: 001010000118896"
echo "  Ki:   BD9044E60EFA8AD9052799E65D8AF224"
echo "  OPc:  C86FD5618B748B85BBC6515C7AEDB9A4"
echo ""

# Delete existing subscriber
echo "Deleting old subscriber..."
mongosh --quiet --eval "
db = db.getSiblingDB('open5gs');
result = db.subscribers.deleteOne({imsi: '001010000118896'});
print('Deleted', result.deletedCount, 'subscriber(s)');
"

# Add subscriber with correct keys
echo ""
echo "Adding subscriber with correct keys..."
mongosh --quiet --eval "
db = db.getSiblingDB('open5gs');
db.subscribers.insertOne({
    schema_version: NumberInt(1),
    imsi: '001010000118896',
    msisdn: [],
    imeisv: '1110000000000000',
    slice: [{
        sst: NumberInt(1),
        default_indicator: true,
        session: [{
            name: 'internet',
            type: NumberInt(3),
            qos: {
                index: NumberInt(9),
                arp: {
                    priority_level: NumberInt(8),
                    pre_emption_capability: NumberInt(1),
                    pre_emption_vulnerability: NumberInt(1)
                }
            },
            ambr: {
                downlink: { value: NumberInt(1), unit: NumberInt(3) },
                uplink: { value: NumberInt(1), unit: NumberInt(3) }
            }
        }]
    }],
    security: {
        k: 'BD9044E60EFA8AD9052799E65D8AF224',
        opc: 'C86FD5618B748B85BBC6515C7AEDB9A4',
        amf: '8000',
        sqn: NumberLong(1184)
    },
    ambr: {
        downlink: { value: NumberInt(1), unit: NumberInt(3) },
        uplink: { value: NumberInt(1), unit: NumberInt(3) }
    },
    access_restriction_data: 32,
    network_access_mode: 2,
    subscriber_status: 0
});
print('✅ Subscriber added successfully');
"

# Verify subscriber
echo ""
echo "Verifying subscriber..."
mongosh --quiet --eval "
db = db.getSiblingDB('open5gs');
db.subscribers.find({imsi: '001010000118896'}, {imsi:1, 'security.k':1, 'security.opc':1}).pretty();
"

# Restart MME
echo ""
echo "Restarting Open5GS MME..."
sudo systemctl restart open5gs-mmed
sleep 2

# Check status
echo ""
echo "Checking MME status..."
sudo systemctl status open5gs-mmed --no-pager | head -10

echo ""
echo "✅ Subscriber update complete!"
echo ""
echo "Next steps:"
echo "  1. Turn off your UE completely"
echo "  2. Wait 10 seconds"
echo "  3. Turn on your UE"
echo "  4. Monitor logs: sudo tail -f /var/log/open5gs/mme.log"
echo ""
