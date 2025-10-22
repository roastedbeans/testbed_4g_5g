#!/bin/bash

set -e

DB_NAME="open5gs"
COLLECTION="subscribers"

# Default subscriber credentials (matches SIM card):
# imsi: 001010000118896
# key: BD9044E60EFA8AD9052799E65D8AF224
# opc: C86FD5618B748B85BBC6515C7AEDB9A4

add_subscriber() {
    local imsi=$1
    local key=$2
    local opc=$3
    
    cat > /tmp/add-sub.js << EOF
db = db.getSiblingDB('$DB_NAME');
db.$COLLECTION.updateOne(
    { imsi: "$imsi" },
    { \$setOnInsert: {
        schema_version: NumberInt(1),
        imsi: "$imsi",
        msisdn: [],
        imeisv: "1110000000000000",
        slice: [{
            sst: NumberInt(1),
            default_indicator: true,
            session: [{
                name: "internet",
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
            k: "$key",
            opc: "$opc",
            amf: "8000",
            sqn: NumberLong(1184)
        },
        ambr: {
            downlink: { value: NumberInt(1), unit: NumberInt(3) },
            uplink: { value: NumberInt(1), unit: NumberInt(3) }
        },
        access_restriction_data: 32,
        network_access_mode: 2,
        subscriber_status: 0
    }},
    { upsert: true }
);
print("Added: $imsi");
EOF

    mongosh --quiet /tmp/add-sub.js
    rm /tmp/add-sub.js
    echo "✅ Subscriber added: IMSI=$imsi"
}

delete_all() {
    echo "db = db.getSiblingDB('$DB_NAME'); db.$COLLECTION.deleteMany({}); print('Deleted all subscribers');" | \
        mongosh --quiet
    echo "✅ All subscribers deleted"
}

list_subs() {
    echo "db = db.getSiblingDB('$DB_NAME'); db.$COLLECTION.find({}, {imsi:1, _id:0}).forEach(s => print(s.imsi));" | \
        mongosh --quiet
}

count_subs() {
    echo "db = db.getSiblingDB('$DB_NAME'); print('Total subscribers:', db.$COLLECTION.count());" | \
        mongosh --quiet
}

show_help() {
    echo "Open5GS Subscriber Management Tool"
    echo ""
    echo "Usage: $0 {add|delete-all|list|count}"
    echo ""
    echo "Commands:"
    echo "  add <imsi> <key> <opc>    Add a new subscriber"
    echo "  delete-all                 Delete all subscribers"
    echo "  list                       List all subscriber IMSIs"
    echo "  count                      Count total subscribers"
    echo ""
    echo "Example:"
    echo "  $0 add 001010000118896 BD9044E60EFA8AD9052799E65D8AF224 C86FD5618B748B85BBC6515C7AEDB9A4"
    echo ""
}

case $1 in
    add)
        if [ -z "$2" ] || [ -z "$3" ] || [ -z "$4" ]; then
            echo "❌ Error: Missing arguments for add command"
            show_help
            exit 1
        fi
        add_subscriber $2 $3 $4
        ;;
    delete-all)
        delete_all
        ;;
    list)
        list_subs
        ;;
    count)
        count_subs
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo "❌ Error: Invalid command '$1'"
        echo ""
        show_help
        exit 1
        ;;
esac