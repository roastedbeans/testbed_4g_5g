#!/bin/bash
# Cellular Base Station Test Infrastructure - Centralized Management
# Usage: ./ssh.sh [legitimate|legitimate_5g|false]

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
    echo "Usage: $0 [legitimate|legitimate_5g|false]"
    echo ""
    echo "Commands:"
    echo "  legitimate     SSH into legitimate base station VM (SDR #1 & SDR #2)"
    echo "  legitimate_5g  SSH into legitimate 5G base station VM (SDR #1)"
    echo "  false          SSH into false base station VM (SDR #3)"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 legitimate     # SSH into legitimate BS"
    echo "  $0 legitimate_5g  # SSH into legitimate 5G BS"
    echo "  $0 false          # SSH into false BS"
}

case "$1" in
    legitimate)
        echo -e "${BLUE}Connecting to legitimate base station VM...${NC}"
        cd legitimate && vagrant ssh
        ;;
    legitimate_5g)
        echo -e "${BLUE}Connecting to legitimate base station VM...${NC}"
        cd legitimate_5g && vagrant ssh
        ;;
    false)
        echo -e "${YELLOW}Connecting to false base station VM...${NC}"
        cd false && vagrant ssh
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
