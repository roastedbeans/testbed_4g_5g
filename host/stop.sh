#!/bin/bash
# False Base Station Attack Infrastructure - Centralized Management
# Usage: ./stop.sh [legitimate|false|both]

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

show_help() {
    echo -e "${BLUE}False Base Station Attack Infrastructure${NC}"
    echo ""
    echo "Usage: $0 [legitimate|false|both]"
    echo ""
    echo "Commands:"
    echo "  legitimate    Stop only legitimate base station VM"
    echo "  false         Stop only false base station VM"
    echo "  both          Stop both VMs in parallel"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 legitimate    # Stop legitimate BS only"
    echo "  $0 false         # Stop false BS only"
    echo "  $0 both          # Stop both VMs"
}

case "$1" in
    legitimate)
        echo -e "${BLUE}Stopping legitimate base station VM...${NC}"
        cd legitimate && vagrant halt
        ;;
    false)
        echo -e "${YELLOW}Stopping false base station VM...${NC}"
        cd false && vagrant halt
        ;;
    both)
        echo -e "${BLUE}Stopping both legitimate and false base station VMs...${NC}"
        cd legitimate && vagrant halt &
        LEGIT_PID=$!
        cd ../false && vagrant halt &
        FALSE_PID=$!
        wait $LEGIT_PID $FALSE_PID
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
