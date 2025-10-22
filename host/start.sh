#!/bin/bash
# Cellular Base Station Test Infrastructure - Centralized Management
# Usage: ./start.sh [legitimate|legitimate_5g|false|both|all]

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
    echo "  legitimate     Start 4G legitimate base station VM (SDR #1 & SDR #2)"
    echo "  legitimate_5g  Start 5G legitimate base station VM (SDR #1)"
    echo "  false          Start false base station VM (SDR #3)"
    echo "  both           Start legitimate and false BS VMs in parallel"
    echo "  all            Start all three VMs in parallel"
    echo "  help           Show this help message"
    echo ""
    echo "⚠️  IMPORTANT: legitimate and legitimate_5g use SDR #1 - run only one!"
    echo ""
    echo "Examples:"
    echo "  $0 legitimate     # Start 4G legitimate BS (SDR #1 & SDR #2)"
    echo "  $0 legitimate_5g  # Start 5G legitimate BS (SDR #1)"
    echo "  $0 false          # Start false BS (SDR #3)"
    echo "  $0 all            # Start all three base stations"
}

case "$1" in
    legitimate)
        echo -e "${BLUE}Starting legitimate base station VM...${NC}"

        # Check if legitimate_5g VM is running
        if pgrep -f "vagrant.*legitimate_5g" >/dev/null 2>&1; then
            echo -e "${RED}ERROR: legitimate_5g VM appears to be running!${NC}"
            echo -e "${RED}Stop it first: cd legitimate_5g && vagrant halt${NC}"
            exit 1
        fi

        cd legitimate && vagrant up
        ;;
    legitimate_5g)
        echo -e "${BLUE}Starting legitimate 5G base station VM...${NC}"
        echo -e "${YELLOW}⚠️  NOTE: This uses SDR #1 - ensure legitimate VM is stopped${NC}"

        # Check if legitimate VM is running
        if pgrep -f "vagrant.*legitimate" >/dev/null 2>&1; then
            echo -e "${RED}ERROR: legitimate VM appears to be running!${NC}"
            echo -e "${RED}Stop it first: cd legitimate && vagrant halt${NC}"
            exit 1
        fi

        cd legitimate_5g && vagrant up legitimate_5g
        ;;
    false)
        echo -e "${YELLOW}Starting false base station VM...${NC}"
        echo -e "${RED}⚠️  WARNING: For RESEARCH and EDUCATIONAL use ONLY${NC}"
        cd false && vagrant up
        ;;
    both)
        echo -e "${BLUE}Starting legitimate (4G) and false base station VMs...${NC}"
        echo -e "${RED}⚠️  WARNING: For RESEARCH and EDUCATIONAL use ONLY${NC}"

        # Check if legitimate_5g VM is running
        if pgrep -f "vagrant.*legitimate_5g" >/dev/null 2>&1; then
            echo -e "${RED}ERROR: legitimate_5g VM appears to be running!${NC}"
            echo -e "${RED}Stop it first: cd legitimate_5g && vagrant halt${NC}"
            exit 1
        fi

        cd legitimate && vagrant up &
        LEGIT_PID=$!
        cd ../false && vagrant up &
        FALSE_PID=$!
        wait $LEGIT_PID $FALSE_PID
        ;;
    all)
        echo -e "${BLUE}Starting all base station VMs...${NC}"
        echo -e "${RED}⚠️  WARNING: For RESEARCH and EDUCATIONAL use ONLY${NC}"
        echo -e "${YELLOW}⚠️  NOTE: Starting legitimate (4G) - use legitimate_5g separately${NC}"
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
