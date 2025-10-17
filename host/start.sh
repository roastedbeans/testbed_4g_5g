#!/bin/bash
# Cellular Base Station Test Infrastructure - Centralized Management
# Usage: ./start.sh [legitimate|legitimate2|false|both|all]

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
    echo "Usage: $0 [legitimate|legitimate2|false|both|all]"
    echo ""
    echo "Commands:"
    echo "  legitimate     Start only first legitimate base station VM"
    echo "  legitimate2    Start only second legitimate base station VM"
    echo "  false          Start only false base station VM"
    echo "  both           Start legitimate and false BS VMs in parallel"
    echo "  all            Start all three VMs in parallel"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 legitimate     # Start legitimate BS #1 only"
    echo "  $0 legitimate2    # Start legitimate BS #2 only"
    echo "  $0 false          # Start false BS only"
    echo "  $0 both           # Start legitimate #1 + false BS"
    echo "  $0 all            # Start all three base stations"
}

case "$1" in
    legitimate)
        echo -e "${BLUE}Starting legitimate base station #1 VM...${NC}"
        cd legitimate && vagrant up
        ;;
    legitimate2)
        echo -e "${BLUE}Starting legitimate base station #2 VM...${NC}"
        cd legitimate2 && vagrant up
        ;;
    false)
        echo -e "${YELLOW}Starting false base station VM...${NC}"
        echo -e "${RED}⚠️  WARNING: For RESEARCH and EDUCATIONAL use ONLY${NC}"
        cd false && vagrant up
        ;;
    both)
        echo -e "${BLUE}Starting legitimate #1 and false base station VMs...${NC}"
        echo -e "${RED}⚠️  WARNING: For RESEARCH and EDUCATIONAL use ONLY${NC}"
        cd legitimate && vagrant up &
        LEGIT_PID=$!
        cd ../false && vagrant up &
        FALSE_PID=$!
        wait $LEGIT_PID $FALSE_PID
        ;;
    all)
        echo -e "${BLUE}Starting all base station VMs...${NC}"
        echo -e "${RED}⚠️  WARNING: For RESEARCH and EDUCATIONAL use ONLY${NC}"
        cd legitimate && vagrant up &
        LEGIT1_PID=$!
        cd ../legitimate2 && vagrant up &
        LEGIT2_PID=$!
        cd ../false && vagrant up &
        FALSE_PID=$!
        wait $LEGIT1_PID $LEGIT2_PID $FALSE_PID
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
