#!/bin/bash
#####################################################################
# CONFIGURE MME FOR NETWORK ACCESSIBILITY
#
# This script configures the MME to listen on the network interface
# for cross-VM connections, while keeping localhost access for local ENB.
#
# Usage: Run this script on the legitimate VM after it starts
#####################################################################

set -e

echo "🔧 Configuring MME for network accessibility..."

# Get the network IP (exclude localhost)
NETWORK_IP=$(ip addr show | grep 'inet ' | grep -v '127.0.0.1' | head -1 | awk '{print $2}' | cut -d'/' -f1)

if [ -z "$NETWORK_IP" ]; then
    echo "❌ Could not detect network IP"
    exit 1
fi

echo "✅ Detected network IP: $NETWORK_IP"

MME_CONFIG="/etc/open5gs/mme.yaml"

# Backup original config
cp "$MME_CONFIG" "${MME_CONFIG}.backup.$(date +%s)"

# Update MME config to listen on network IP with explicit ports
cat > /tmp/mme_network_config.yaml << EOF
mme:
  freeDiameter: /etc/freeDiameter/mme.conf
  s1ap:
    server:
      - address: 127.0.1.2
      - address: $NETWORK_IP
        port: 36412
  gtpc:
    server:
      - address: 127.0.0.2
      - address: $NETWORK_IP
        port: 2123
EOF

# Merge with existing config
python3 -c "
import yaml
import sys

# Load existing config
with open('$MME_CONFIG', 'r') as f:
    config = yaml.safe_load(f)

# Load network config
with open('/tmp/mme_network_config.yaml', 'r') as f:
    network_config = yaml.safe_load(f)

# Update mme section
config['mme'].update(network_config['mme'])

# Write back
with open('$MME_CONFIG', 'w') as f:
    yaml.dump(config, f, default_flow_style=False, indent=2)

print('✅ Updated MME config with network IP: $NETWORK_IP')
"

echo "🔄 Restarting Open5GS MME service..."
systemctl restart open5gs-mmed

echo "✅ MME now listening on:"
echo "   S1AP: 127.0.1.2 + $NETWORK_IP:36412"
echo "   GTP-C: 127.0.0.2 + $NETWORK_IP:2123"

# Verify ports are listening
echo "🔍 Verifying ports..."
sleep 2

if netstat -tuln | grep -q ":36412 "; then
    echo "✅ S1AP port 36412 is listening"
else
    echo "❌ S1AP port 36412 not found"
fi

if netstat -tuln | grep -q ":2123 "; then
    echo "✅ GTP-C port 2123 is listening"
else
    echo "❌ GTP-C port 2123 not found"
fi

echo ""
echo "📋 legitimate2 ENB should now connect to MME at: $NETWORK_IP"
echo "   Update legitimate2/configs/srsran/enb.conf:"
echo "   mme_addr = $NETWORK_IP"
