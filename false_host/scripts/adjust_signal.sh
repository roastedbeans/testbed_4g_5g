#!/bin/bash
#####################################################################
# SIGNAL ADJUSTMENT TOOL
# 
# Manual signal strength adjustment for demonstrations
# Allows real-time TX gain modification
#####################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

#####################################################################
# Functions
#####################################################################

print_banner() {
    echo -e "${BLUE}======================================${NC}"
    echo -e "${BLUE}   Signal Adjustment Tool${NC}"
    echo -e "${BLUE}======================================${NC}"
    echo ""
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  increase <bs> <amount>    Increase TX gain"
    echo "  decrease <bs> <amount>    Decrease TX gain"
    echo "  set <bs> <value>          Set absolute TX gain"
    echo "  demo                      Run interactive demo mode"
    echo "  help                      Show this help message"
    echo ""
    echo "Parameters:"
    echo "  <bs>       Base station: 'legit' or 'false'"
    echo "  <amount>   Change in dB (e.g., 5)"
    echo "  <value>    Absolute value in dB (e.g., 75)"
    echo ""
    echo "Examples:"
    echo "  $0 increase false 5       # Increase false BS by 5 dB"
    echo "  $0 decrease legit 3       # Decrease legitimate BS by 3 dB"
    echo "  $0 set false 80           # Set false BS to 80 dB"
    echo "  $0 demo                   # Interactive demonstration mode"
    echo ""
}

get_current_gain() {
    local bs_type=$1
    local config_file=""
    
    if [ "$bs_type" == "legit" ]; then
        config_file="/etc/srsran/legitimate/enb_4g.conf"
    else
        config_file="/etc/srsran/false/enb_4g_rogue.conf"
    fi
    
    if [ -f "$config_file" ]; then
        grep "^tx_gain" "$config_file" | awk '{print $3}'
    else
        echo "0"
    fi
}

set_gain() {
    local bs_type=$1
    local new_gain=$2
    local config_file=""
    local bs_name=""
    
    if [ "$bs_type" == "legit" ]; then
        config_file="/etc/srsran/legitimate/enb_4g.conf"
        bs_name="Legitimate BS"
    else
        config_file="/etc/srsran/false/enb_4g_rogue.conf"
        bs_name="False BS"
    fi
    
    # Validate gain value (0-89 dB for USRP B200)
    if [ "$new_gain" -lt 0 ] || [ "$new_gain" -gt 89 ]; then
        echo -e "${RED}Error: TX gain must be between 0 and 89 dB${NC}"
        return 1
    fi
    
    # Update configuration file
    if [ -f "$config_file" ]; then
        sudo sed -i "s/^tx_gain = .*/tx_gain = ${new_gain}/" "$config_file"
        echo -e "${GREEN}✓ ${bs_name} TX gain set to ${new_gain} dB${NC}"
        
        # Log the change
        echo "[$(date '+%Y-%m-%d %H:%M:%S')] ${bs_name}: TX gain adjusted to ${new_gain} dB" >> /tmp/signal_adjustments.log
    else
        echo -e "${RED}Error: Configuration file not found: $config_file${NC}"
        return 1
    fi
}

increase_gain() {
    local bs_type=$1
    local amount=$2
    local current=$(get_current_gain "$bs_type")
    local new_gain=$((current + amount))
    
    echo "Current TX gain: ${current} dB"
    echo "Increasing by: ${amount} dB"
    echo "New TX gain: ${new_gain} dB"
    echo ""
    
    set_gain "$bs_type" "$new_gain"
}

decrease_gain() {
    local bs_type=$1
    local amount=$2
    local current=$(get_current_gain "$bs_type")
    local new_gain=$((current - amount))
    
    echo "Current TX gain: ${current} dB"
    echo "Decreasing by: ${amount} dB"
    echo "New TX gain: ${new_gain} dB"
    echo ""
    
    set_gain "$bs_type" "$new_gain"
}

demo_mode() {
    echo -e "${YELLOW}======================================${NC}"
    echo -e "${YELLOW}  Interactive Signal Adjustment Demo${NC}"
    echo -e "${YELLOW}======================================${NC}"
    echo ""
    echo "This mode allows you to adjust signal strengths in real-time"
    echo "to demonstrate UE handover behavior."
    echo ""
    echo "Current Configuration:"
    echo "  Legitimate BS: $(get_current_gain 'legit') dB"
    echo "  False BS:      $(get_current_gain 'false') dB"
    echo ""
    
    while true; do
        echo ""
        echo "Options:"
        echo "  1) Increase legitimate BS signal"
        echo "  2) Decrease legitimate BS signal"
        echo "  3) Increase false BS signal"
        echo "  4) Decrease false BS signal"
        echo "  5) Reset to handover preset (legit: 65, false: 80)"
        echo "  6) Show current values"
        echo "  q) Quit"
        echo ""
        read -p "Choose an option: " choice
        
        case $choice in
            1)
                read -p "Enter amount to increase (dB): " amount
                increase_gain "legit" "$amount"
                ;;
            2)
                read -p "Enter amount to decrease (dB): " amount
                decrease_gain "legit" "$amount"
                ;;
            3)
                read -p "Enter amount to increase (dB): " amount
                increase_gain "false" "$amount"
                ;;
            4)
                read -p "Enter amount to decrease (dB): " amount
                decrease_gain "false" "$amount"
                ;;
            5)
                echo "Resetting to handover preset..."
                set_gain "legit" 65
                set_gain "false" 80
                ;;
            6)
                echo ""
                echo "Current Configuration:"
                echo "  Legitimate BS: $(get_current_gain 'legit') dB"
                echo "  False BS:      $(get_current_gain 'false') dB"
                local diff=$(($(get_current_gain 'false') - $(get_current_gain 'legit')))
                echo "  Difference:    ${diff} dB (False BS advantage)"
                ;;
            q|Q)
                echo "Exiting demo mode..."
                break
                ;;
            *)
                echo -e "${RED}Invalid option${NC}"
                ;;
        esac
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
    "increase")
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Error: Missing arguments${NC}"
            show_usage
            exit 1
        fi
        increase_gain "$2" "$3"
        ;;
    "decrease")
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Error: Missing arguments${NC}"
            show_usage
            exit 1
        fi
        decrease_gain "$2" "$3"
        ;;
    "set")
        if [ -z "$2" ] || [ -z "$3" ]; then
            echo -e "${RED}Error: Missing arguments${NC}"
            show_usage
            exit 1
        fi
        set_gain "$2" "$3"
        ;;
    "demo")
        demo_mode
        ;;
    "help"|"-h"|"--help")
        show_usage
        ;;
    *)
        echo -e "${RED}Error: Invalid command '$1'${NC}"
        show_usage
        exit 1
        ;;
esac

