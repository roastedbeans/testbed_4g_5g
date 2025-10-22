#!/bin/bash
#####################################################################
# SIGNAL MANAGER
# 
# Manages TX/RX gain for legitimate and false base stations
# Enables signal strength manipulation for handover demonstrations
#####################################################################

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Signal strength presets
LEGITIMATE_TX_GAIN_LOW=60
LEGITIMATE_TX_GAIN_NORMAL=65
LEGITIMATE_TX_GAIN_HIGH=70

FALSE_TX_GAIN_LOW=70
FALSE_TX_GAIN_NORMAL=80
FALSE_TX_GAIN_HIGH=85

RX_GAIN_DEFAULT=40

# Log file
SIGNAL_LOG="/tmp/signal_strength.log"

#####################################################################
# Functions
#####################################################################

print_banner() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}     Signal Strength Manager${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

log_signal() {
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] $1" | tee -a "$SIGNAL_LOG"
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  set-legitimate <gain>    Set TX gain for legitimate BS (60-70 recommended)"
    echo "  set-false <gain>         Set TX gain for false BS (75-85 recommended)"
    echo "  preset-handover          Configure for handover demo (legit: 65, false: 80)"
    echo "  preset-equal             Set equal signal strength for testing"
    echo "  ramp-up-false            Gradually increase false BS signal"
    echo "  ramp-down-false          Gradually decrease false BS signal"
    echo "  status                   Show current signal configuration"
    echo "  monitor                  Continuously monitor signal levels"
    echo "  help                     Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 preset-handover       # Setup for handover demonstration"
    echo "  $0 ramp-up-false         # Gradually increase false BS signal"
    echo "  $0 set-legitimate 65     # Set legitimate BS TX gain to 65 dB"
    echo ""
}

set_legitimate_gain() {
    local tx_gain=$1
    local rx_gain=${2:-$RX_GAIN_DEFAULT}
    
    echo -e "${GREEN}Setting legitimate BS signal strength...${NC}"
    echo "  TX Gain: ${tx_gain} dB"
    echo "  RX Gain: ${rx_gain} dB"
    
    # Update enb.conf
    if [ -f "/etc/srsran/legitimate/enb_4g.conf" ]; then
        sudo sed -i "s/^tx_gain = .*/tx_gain = ${tx_gain}/" /etc/srsran/legitimate/enb_4g.conf
        sudo sed -i "s/^rx_gain = .*/rx_gain = ${rx_gain}/" /etc/srsran/legitimate/enb_4g.conf
        echo -e "${GREEN}✓ Updated 4G configuration${NC}"
    fi
    
    # Update gnb.yml
    if [ -f "/etc/srsran/legitimate/gnb_5g.yml" ]; then
        sudo sed -i "s/^  tx_gain: .*/  tx_gain: ${tx_gain}/" /etc/srsran/legitimate/gnb_5g.yml
        sudo sed -i "s/^  rx_gain: .*/  rx_gain: ${rx_gain}/" /etc/srsran/legitimate/gnb_5g.yml
        echo -e "${GREEN}✓ Updated 5G configuration${NC}"
    fi
    
    log_signal "LEGITIMATE BS: TX=${tx_gain}dB, RX=${rx_gain}dB"
}

set_false_gain() {
    local tx_gain=$1
    local rx_gain=${2:-$RX_GAIN_DEFAULT}
    
    echo -e "${YELLOW}Setting false BS signal strength...${NC}"
    echo "  TX Gain: ${tx_gain} dB"
    echo "  RX Gain: ${rx_gain} dB"
    
    # Update enb.conf
    if [ -f "/etc/srsran/false/enb_4g_rogue.conf" ]; then
        sudo sed -i "s/^tx_gain = .*/tx_gain = ${tx_gain}/" /etc/srsran/false/enb_4g_rogue.conf
        sudo sed -i "s/^rx_gain = .*/rx_gain = ${rx_gain}/" /etc/srsran/false/enb_4g_rogue.conf
        echo -e "${GREEN}✓ Updated 4G rogue configuration${NC}"
    fi
    
    # Update gnb.yml
    if [ -f "/etc/srsran/false/gnb_5g_rogue.yml" ]; then
        sudo sed -i "s/^  tx_gain: .*/  tx_gain: ${tx_gain}/" /etc/srsran/false/gnb_5g_rogue.yml
        sudo sed -i "s/^  rx_gain: .*/  rx_gain: ${rx_gain}/" /etc/srsran/false/gnb_5g_rogue.yml
        echo -e "${GREEN}✓ Updated 5G rogue configuration${NC}"
    fi
    
    log_signal "FALSE BS: TX=${tx_gain}dB, RX=${rx_gain}dB"
}

preset_handover() {
    echo -e "${BLUE}Configuring signal strengths for handover demonstration...${NC}"
    echo ""
    echo "Legitimate BS: Lower signal (65 dB)"
    echo "False BS: Higher signal (80 dB)"
    echo ""
    echo "This configuration ensures UE will prefer false BS due to higher signal strength."
    echo ""
    
    set_legitimate_gain 65
    echo ""
    set_false_gain 80
    echo ""
    echo -e "${GREEN}✓ Handover preset configured successfully${NC}"
    log_signal "PRESET: Handover configuration applied"
}

preset_equal() {
    echo -e "${BLUE}Configuring equal signal strengths for testing...${NC}"
    echo ""
    
    set_legitimate_gain 70
    echo ""
    set_false_gain 70
    echo ""
    echo -e "${GREEN}✓ Equal signal preset configured${NC}"
    log_signal "PRESET: Equal signal configuration applied"
}

ramp_up_false() {
    local start_gain=${1:-60}
    local end_gain=${2:-85}
    local step=${3:-5}
    local interval=${4:-5}
    
    echo -e "${YELLOW}Ramping up false BS signal strength...${NC}"
    echo "Start: ${start_gain} dB"
    echo "End: ${end_gain} dB"
    echo "Step: ${step} dB"
    echo "Interval: ${interval} seconds"
    echo ""
    
    for ((gain=$start_gain; gain<=$end_gain; gain+=$step)); do
        echo -e "${YELLOW}→ Setting TX gain to ${gain} dB${NC}"
        set_false_gain $gain
        log_signal "RAMP UP: False BS signal increased to ${gain}dB"
        
        if [ $gain -lt $end_gain ]; then
            echo "Waiting ${interval} seconds..."
            sleep $interval
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ Ramp up complete - False BS at ${end_gain} dB${NC}"
    log_signal "RAMP UP: Complete at ${end_gain}dB"
}

ramp_down_false() {
    local start_gain=${1:-85}
    local end_gain=${2:-60}
    local step=${3:-5}
    local interval=${4:-5}
    
    echo -e "${YELLOW}Ramping down false BS signal strength...${NC}"
    echo "Start: ${start_gain} dB"
    echo "End: ${end_gain} dB"
    echo "Step: ${step} dB"
    echo "Interval: ${interval} seconds"
    echo ""
    
    for ((gain=$start_gain; gain>=$end_gain; gain-=$step)); do
        echo -e "${YELLOW}→ Setting TX gain to ${gain} dB${NC}"
        set_false_gain $gain
        log_signal "RAMP DOWN: False BS signal decreased to ${gain}dB"
        
        if [ $gain -gt $end_gain ]; then
            echo "Waiting ${interval} seconds..."
            sleep $interval
        fi
    done
    
    echo ""
    echo -e "${GREEN}✓ Ramp down complete - False BS at ${end_gain} dB${NC}"
    log_signal "RAMP DOWN: Complete at ${end_gain}dB"
}

show_status() {
    echo -e "${BLUE}Current Signal Configuration:${NC}"
    echo ""
    
    # Check legitimate BS
    if [ -f "/etc/srsran/legitimate/enb_4g.conf" ]; then
        local legit_tx=$(grep "^tx_gain" /etc/srsran/legitimate/enb_4g.conf | awk '{print $3}')
        local legit_rx=$(grep "^rx_gain" /etc/srsran/legitimate/enb_4g.conf | awk '{print $3}')
        echo -e "${GREEN}Legitimate BS (4G):${NC}"
        echo "  TX Gain: ${legit_tx} dB"
        echo "  RX Gain: ${legit_rx} dB"
    fi
    
    # Check false BS
    if [ -f "/etc/srsran/false/enb_4g_rogue.conf" ]; then
        local false_tx=$(grep "^tx_gain" /etc/srsran/false/enb_4g_rogue.conf | awk '{print $3}')
        local false_rx=$(grep "^rx_gain" /etc/srsran/false/enb_4g_rogue.conf | awk '{print $3}')
        echo ""
        echo -e "${YELLOW}False BS (4G):${NC}"
        echo "  TX Gain: ${false_tx} dB"
        echo "  RX Gain: ${false_rx} dB"
        
        # Calculate difference
        local diff=$((false_tx - legit_tx))
        echo ""
        echo "Signal Difference: ${diff} dB (False BS stronger)" 
    fi
    
    echo ""
}

monitor_signals() {
    echo -e "${BLUE}Monitoring signal levels (Ctrl+C to stop)...${NC}"
    echo ""
    
    while true; do
        clear
        show_status
        echo ""
        echo "Last updated: $(date '+%Y-%m-%d %H:%M:%S')"
        sleep 5
    done
}

#####################################################################
# Main
#####################################################################

print_banner

if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

case "$1" in
    "set-legitimate")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: TX gain value required${NC}"
            exit 1
        fi
        set_legitimate_gain "$2" "${3:-$RX_GAIN_DEFAULT}"
        ;;
    "set-false")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: TX gain value required${NC}"
            exit 1
        fi
        set_false_gain "$2" "${3:-$RX_GAIN_DEFAULT}"
        ;;
    "preset-handover")
        preset_handover
        ;;
    "preset-equal")
        preset_equal
        ;;
    "ramp-up-false")
        ramp_up_false "${2:-60}" "${3:-85}" "${4:-5}" "${5:-5}"
        ;;
    "ramp-down-false")
        ramp_down_false "${2:-85}" "${3:-60}" "${4:-5}" "${5:-5}"
        ;;
    "status")
        show_status
        ;;
    "monitor")
        monitor_signals
        ;;
    "help")
        show_usage
        ;;
    *)
        echo -e "${RED}Error: Invalid command '$1'${NC}"
        echo ""
        show_usage
        exit 1
        ;;
esac

echo ""
echo -e "${GREEN}Signal management complete${NC}"

