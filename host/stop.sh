#!/bin/bash
# Cellular Base Station Test Infrastructure - Centralized Management
# Usage: ./stop.sh [legitimate|legitimate_5g|false|both|all]

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}Cellular Base Station Test Infrastructure${NC}"
    echo ""
    echo "Usage: $0 [legitimate|legitimate_5g|false|both|all]"
    echo ""
    echo "Commands:"
    echo "  legitimate     Stop 4G legitimate base station VM (SDR #1 & SDR #2)"
    echo "  legitimate_5g  Stop 5G legitimate base station VM (SDR #1)"
    echo "  false          Stop false base station VM (SDR #3)"
    echo "  both           Stop legitimate and false BS VMs in parallel"
    echo "  all            Stop all three VMs in parallel"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 legitimate     # Stop 4G legitimate BS (SDR #1 & SDR #2)"
    echo "  $0 legitimate_5g  # Stop 5G legitimate BS (SDR #1)"
    echo "  $0 false          # Stop false BS (SDR #3)"
    echo "  $0 all            # Stop all three base stations"
}

case "$1" in
    legitimate)
        echo -e "${BLUE}Stopping legitimate base station #1 & #2 VM...${NC}"
        cd legitimate && vagrant halt
        ;;
    legitimate_5g)
        echo -e "${BLUE}Stopping legitimate 5G base station VM...${NC}"
        cd legitimate_5g && vagrant halt legitimate_5g
        ;;
    false)
        echo -e "${YELLOW}Stopping false base station VM...${NC}"
        cd false && vagrant halt
        ;;
    both)
        echo -e "${BLUE}Stopping legitimate #1 and false base station VMs...${NC}"
        cd legitimate && vagrant halt &
        LEGIT_PID=$!
        cd ../false && vagrant halt &
        FALSE_PID=$!
        wait $LEGIT_PID $FALSE_PID
        ;;
    all)
        echo -e "${BLUE}Stopping all base station VMs...${NC}"
        cd legitimate && vagrant halt &
        LEGIT_PID=$!
        cd ../legitimate_5g && vagrant halt &
        LEGIT5G_PID=$!
        cd ../false && vagrant halt &
        FALSE_PID=$!
        wait $LEGIT_PID $LEGIT5G_PID $FALSE_PID
        ;;
    help|--help|-h)
        show_help
        ;;
    *)
        echo -e "${RED}Error: Invalid argument '$1'${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

echo -e "${GREEN}✅ Operation completed${NC}"
