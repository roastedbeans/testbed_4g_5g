#!/bin/bash
# False Base Station Attack Infrastructure - Centralized Management
# Usage: ./start.sh [legitimate|false|both]

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
    echo "  legitimate    Start only legitimate base station VM"
    echo "  false         Start only false base station VM"
    echo "  both          Start both VMs in parallel"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 legitimate    # Start legitimate BS only"
    echo "  $0 false         # Start false BS only"
    echo "  $0 both          # Start both VMs"
}

case "$1" in
    legitimate)
        echo -e "${BLUE}Starting legitimate base station VM...${NC}"
        cd legitimate && vagrant up
        ;;
    false)
        echo -e "${YELLOW}Starting false base station VM...${NC}"
        echo -e "${RED}⚠️  WARNING: For RESEARCH and EDUCATIONAL use ONLY${NC}"
        cd false && vagrant up
        ;;
    both)
        echo -e "${BLUE}Starting both legitimate and false base station VMs...${NC}"
        echo -e "${RED}⚠️  WARNING: For RESEARCH and EDUCATIONAL use ONLY${NC}"
        cd legitimate && vagrant up &
        LEGIT_PID=$!
        cd ../false && vagrant up &
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
