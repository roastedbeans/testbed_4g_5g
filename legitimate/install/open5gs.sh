#!/bin/bash

# Open5GS Setup Script for Ubuntu 24.04
# Based on SDR Documentation

echo "=== Open5GS Setup Script ==="

# Install MongoDB for subscriber management
echo "Installing MongoDB..."

# Install MongoDB from official repository
sudo apt-get install -y gnupg curl
curl -fsSL https://www.mongodb.org/static/pgp/server-7.0.asc | \
    sudo gpg --batch --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg

echo "deb [ arch=amd64,arm64 signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg ] https://repo.mongodb.org/apt/ubuntu jammy/mongodb-org/7.0 multiverse" | \
    sudo tee /etc/apt/sources.list.d/mongodb-org-7.0.list

sudo apt-get update
sudo apt-get install -y mongodb-org

# Start MongoDB
sudo systemctl start mongod
sudo systemctl enable mongod

echo "✅ MongoDB installed successfully"

# Install Open5GS
echo "Installing Open5GS..."
sudo apt install software-properties-common -y
sudo add-apt-repository ppa:open5gs/latest -y
sudo apt update
sudo apt install open5gs -y

echo "✅ Open5GS installed successfully"

# Configure Open5GS for test network (MCC=001, MNC=01)
echo "Configuring Open5GS..."

# Backup original configurations
sudo cp /etc/open5gs/mme.yaml /etc/open5gs/mme.yaml.bak 2>/dev/null || true
sudo cp /etc/open5gs/amf.yaml /etc/open5gs/amf.yaml.bak 2>/dev/null || true

# Configure MME for 4G
sudo tee /etc/open5gs/mme.yaml > /dev/null <<EOF
logger:
  file:
    path: /var/log/open5gs/mme.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

mme:
  freeDiameter: /etc/freeDiameter/mme.conf
  s1ap:
    server:
      - address: 127.0.1.2
  gtpc:
    server:
      - address: 127.0.0.2
    client:
      sgwc:
        - address: 127.0.0.3
      smf:
       - address: 127.0.0.4
  metrics:
    server:
      - address: 127.0.0.2
        port: 9090
  gummei:
    - plmn_id:
        mcc: 001
        mnc: 01
      mme_gid: 2
      mme_code: 1
  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 7
  security:
    integrity_order : [ EIA2, EIA1, EIA0 ]
    ciphering_order : [ EEA0, EEA1, EEA2 ]
  network_name:
    full: "001 01"
    short: "001 01"
  mme_name: open5gs-mme0
  time:
#    t3402:
#      value: 720   # 12 minutes * 60 = 720 seconds
#    t3412:
#      value: 3240  # 54 minutes * 60 = 3240 seconds
#    t3423:
#      value: 720   # 12 minutes * 60 = 720 seconds
EOF

# Configure AMF for 5G
sudo tee /etc/open5gs/amf.yaml > /dev/null <<EOF
logger:
  file:
    path: /var/log/open5gs/amf.log
#  level: info   # fatal|error|warn|info(default)|debug|trace

global:
  max:
    ue: 1024  # The number of UE can be increased depending on memory size.
#    peer: 64

amf:
  sbi:
    server:
      - address: 127.0.0.5
        port: 7777
    client:
      nrf:
        - uri: http://127.0.0.10:7777
      scp:
        - uri: http://127.0.0.200:7777
  ngap:
    server:
      - address: 127.0.0.5
  metrics:
    server:
      - address: 127.0.0.5
        port: 9090
  guami:
    - plmn_id:
        mcc: 001
        mnc: 01
      amf_id:
        region: 2
        set: 1
  tai:
    - plmn_id:
        mcc: 001
        mnc: 01
      tac: 7
  plmn_support:
    - plmn_id:
        mcc: 001
        mnc: 01
      s_nssai:
        - sst: 1
  security:
    integrity_order : [ NIA2, NIA1, NIA0 ]
    ciphering_order : [ NEA0, NEA1, NEA2 ]
  network_name:
    full: "001 01"
    short: "001 01"
  amf_name: open5gs-amf0
  time:
#    t3502:
#      value: 720   # 12 minutes * 60 = 720 seconds
    t3512:
      value: 540    # 9 minutes * 60 = 540 seconds
EOF

echo "✅ Open5GS core components installation completed!"
echo ""
echo "📋 Subscriber Management:"
echo "   Use the subscriber.sh script to manage subscribers:"
echo "   sudo /usr/local/bin/subscriber.sh add <imsi> <key> <opc>"
echo "   sudo /usr/local/bin/subscriber.sh list"
echo "   sudo /usr/local/bin/subscriber.sh count"
echo ""
echo "Example:"
echo "   sudo /usr/local/bin/subscriber.sh add 001010000118896 BD9044E60EFA8AD9052799E65D8AF224 C86FD5618B748B85BBC6515C7AEDB9A4"
