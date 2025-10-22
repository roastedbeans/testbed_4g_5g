#!/bin/bash
#####################################################################
# HANDOVER MONITOR
# 
# Monitors and logs UE handover events between legitimate and false BS
# Tracks signal strength, connection status, and timing
#####################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

# Log files
HANDOVER_LOG="/tmp/handover_events.log"
LEGITIMATE_LOG="/tmp/legitimate_enb.log"
FALSE_LOG="/tmp/false_enb.log"
METRICS_LOG="/tmp/handover_metrics.csv"

#####################################################################
# Functions
#####################################################################

print_banner() {
    echo -e "${CYAN}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║              HANDOVER MONITOR v1.0                     ║"
    echo "║     Real-time UE Handover Tracking & Analysis          ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

show_usage() {
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -m, --mode <live|replay>     Monitor mode (default: live)"
    echo "  -i, --interval <seconds>     Update interval (default: 2)"
    echo "  -l, --log <file>             Custom log file location"
    echo "  -e, --export <file>          Export events to file"
    echo "  -h, --help                   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0                           # Start live monitoring"
    echo "  $0 -i 5                      # Update every 5 seconds"
    echo "  $0 -e handover_report.txt    # Export events to file"
    echo ""
}

initialize_logs() {
    # Create log directory if needed
    mkdir -p "$(dirname "$HANDOVER_LOG")"
    
    # Initialize handover log with header
    if [ ! -f "$HANDOVER_LOG" ]; then
        echo "timestamp,event_type,base_station,ue_id,signal_info,details" > "$HANDOVER_LOG"
    fi
    
    # Initialize metrics CSV
    if [ ! -f "$METRICS_LOG" ]; then
        echo "timestamp,legitimate_ues,false_ues,handovers_to_false,handovers_to_legit,total_handovers" > "$METRICS_LOG"
    fi
}

log_event() {
    local event_type=$1
    local base_station=$2
    local ue_id=$3
    local signal_info=$4
    local details=$5
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$timestamp,$event_type,$base_station,$ue_id,$signal_info,$details" >> "$HANDOVER_LOG"
}

get_connected_ues() {
    local bs_type=$1  # "legitimate" or "false"
    local log_file=""
    
    if [ "$bs_type" == "legitimate" ]; then
        log_file="$LEGITIMATE_LOG"
    else
        log_file="$FALSE_LOG"
    fi
    
    if [ -f "$log_file" ]; then
        # Count unique UE connections in the last minute
        local count=$(tail -100 "$log_file" 2>/dev/null | grep -c "RRC Connection" || echo "0")
        echo "$count"
    else
        echo "0"
    fi
}

detect_handover_events() {
    # Parse logs for handover indicators
    local events=0
    
    # Check legitimate BS log for handovers
    if [ -f "$LEGITIMATE_LOG" ]; then
        events=$(tail -50 "$LEGITIMATE_LOG" 2>/dev/null | grep -c "Handover" || echo "0")
    fi
    
    # Check false BS log for new connections (potential handovers)
    if [ -f "$FALSE_LOG" ]; then
        local new_conn=$(tail -50 "$FALSE_LOG" 2>/dev/null | grep -c "RRC Connection Request" || echo "0")
        events=$((events + new_conn))
    fi
    
    echo "$events"
}

get_signal_strength() {
    local bs_type=$1
    local config_file=""
    
    if [ "$bs_type" == "legitimate" ]; then
        config_file="/etc/srsran/legitimate/enb_4g.conf"
    else
        config_file="/etc/srsran/false/enb_4g_rogue.conf"
    fi
    
    if [ -f "$config_file" ]; then
        grep "^tx_gain" "$config_file" | awk '{print $3}'
    else
        echo "N/A"
    fi
}

display_status() {
    clear
    print_banner
    
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    local legit_ues=$(get_connected_ues "legitimate")
    local false_ues=$(get_connected_ues "false")
    local legit_signal=$(get_signal_strength "legitimate")
    local false_signal=$(get_signal_strength "false")
    
    echo -e "${BLUE}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║               CONNECTION STATUS                        ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════╣${NC}"
    
    # Legitimate BS
    if [ "$legit_ues" -gt 0 ]; then
        echo -e "${GREEN}║  Legitimate BS:  ✓ ACTIVE (${legit_ues} UE connected)        ║${NC}"
    else
        echo -e "${YELLOW}║  Legitimate BS:  ○ No UEs connected                  ║${NC}"
    fi
    echo -e "${BLUE}║    TX Power:     ${legit_signal} dB                              ║${NC}"
    echo -e "${BLUE}║    PLMN:         001/01 (MCC/MNC)                     ║${NC}"
    echo -e "${BLUE}║    PCI:          1                                    ║${NC}"
    echo -e "${BLUE}╠════════════════════════════════════════════════════════╣${NC}"
    
    # False BS
    if [ "$false_ues" -gt 0 ]; then
        echo -e "${RED}║  False BS:       ⚠ ACTIVE (${false_ues} UE connected)           ║${NC}"
    else
        echo -e "${YELLOW}║  False BS:       ○ No UEs connected                  ║${NC}"
    fi
    echo -e "${BLUE}║    TX Power:     ${false_signal} dB                              ║${NC}"
    echo -e "${BLUE}║    PLMN:         001/01 (MCC/MNC)                     ║${NC}"
    echo -e "${BLUE}║    PCI:          2                                    ║${NC}"
    echo -e "${BLUE}╚════════════════════════════════════════════════════════╝${NC}"
    
    echo ""
    
    # Signal comparison
    if [ "$legit_signal" != "N/A" ] && [ "$false_signal" != "N/A" ]; then
        local diff=$((false_signal - legit_signal))
        if [ $diff -gt 0 ]; then
            echo -e "${YELLOW}⚡ False BS signal is ${diff} dB STRONGER${NC}"
            echo -e "${YELLOW}   → UE will prefer false BS for handover${NC}"
        elif [ $diff -lt 0 ]; then
            echo -e "${GREEN}⚡ Legitimate BS signal is $((diff * -1)) dB stronger${NC}"
            echo -e "${GREEN}   → UE will remain on legitimate BS${NC}"
        else
            echo -e "${BLUE}⚡ Both BS have equal signal strength${NC}"
        fi
    fi
    
    echo ""
    
    # Recent events
    echo -e "${CYAN}╔════════════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║              RECENT HANDOVER EVENTS                    ║${NC}"
    echo -e "${CYAN}╚════════════════════════════════════════════════════════╝${NC}"
    
    if [ -f "$HANDOVER_LOG" ]; then
        tail -5 "$HANDOVER_LOG" | while IFS=',' read -r ts event bs ue sig details; do
            if [ "$event" != "timestamp" ]; then
                echo "  [$ts] $event → $bs"
            fi
        done
    else
        echo "  No events recorded yet"
    fi
    
    echo ""
    echo -e "${BLUE}Last updated: $timestamp${NC}"
    echo -e "${BLUE}Press Ctrl+C to stop monitoring${NC}"
}

monitor_logs() {
    echo -e "${GREEN}Starting log monitoring...${NC}"
    echo ""
    
    # Monitor both logs for handover events
    (
        if [ -f "$LEGITIMATE_LOG" ]; then
            tail -f "$LEGITIMATE_LOG" 2>/dev/null | while read line; do
                if echo "$line" | grep -q "RRC Connection\|Handover\|UE attached"; then
                    log_event "connection" "legitimate" "auto" "N/A" "$line"
                fi
            done
        fi
    ) &
    
    (
        if [ -f "$FALSE_LOG" ]; then
            tail -f "$FALSE_LOG" 2>/dev/null | while read line; do
                if echo "$line" | grep -q "RRC Connection\|Handover\|UE attached"; then
                    log_event "connection" "false" "auto" "N/A" "$line"
                fi
            done
        fi
    ) &
}

live_monitor() {
    local interval=${1:-2}
    
    initialize_logs
    monitor_logs
    
    while true; do
        display_status
        sleep "$interval"
    done
}

export_report() {
    local output_file=$1
    
    echo "Exporting handover report to $output_file..."
    
    {
        echo "=========================================="
        echo "     HANDOVER ANALYSIS REPORT"
        echo "=========================================="
        echo ""
        echo "Generated: $(date '+%Y-%m-%d %H:%M:%S')"
        echo ""
        echo "Configuration:"
        echo "  Legitimate BS TX Gain: $(get_signal_strength 'legitimate') dB"
        echo "  False BS TX Gain: $(get_signal_strength 'false') dB"
        echo ""
        echo "Events:"
        echo ""
        
        if [ -f "$HANDOVER_LOG" ]; then
            cat "$HANDOVER_LOG"
        else
            echo "No events recorded"
        fi
        
        echo ""
        echo "=========================================="
    } > "$output_file"
    
    echo -e "${GREEN}✓ Report exported to $output_file${NC}"
}

#####################################################################
# Main
#####################################################################

# Parse command line arguments
MODE="live"
INTERVAL=2
EXPORT_FILE=""

while [[ $# -gt 0 ]]; do
    case $1 in
        -m|--mode)
            MODE="$2"
            shift 2
            ;;
        -i|--interval)
            INTERVAL="$2"
            shift 2
            ;;
        -l|--log)
            HANDOVER_LOG="$2"
            shift 2
            ;;
        -e|--export)
            EXPORT_FILE="$2"
            shift 2
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

# Execute based on options
if [ -n "$EXPORT_FILE" ]; then
    print_banner
    export_report "$EXPORT_FILE"
else
    case "$MODE" in
        "live")
            live_monitor "$INTERVAL"
            ;;
        *)
            echo -e "${RED}Error: Invalid mode '$MODE'${NC}"
            show_usage
            exit 1
            ;;
    esac
fi

