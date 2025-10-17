#!/bin/bash
# Cellular Base Station Test Infrastructure - Centralized Management
# Usage: ./ssh.sh [legitimate|legitimate2|false]

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
    echo "Usage: $0 [legitimate|legitimate2|false]"
    echo ""
    echo "Commands:"
    echo "  legitimate     SSH into first legitimate base station VM"
    echo "  legitimate2    SSH into second legitimate base station VM"
    echo "  false          SSH into false base station VM"
    echo "  help           Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 legitimate     # SSH into legitimate BS #1"
    echo "  $0 legitimate2    # SSH into legitimate BS #2"
    echo "  $0 false          # SSH into false BS"
}

case "$1" in
    legitimate)
        echo -e "${BLUE}Connecting to legitimate base station #1 VM...${NC}"
        cd legitimate && vagrant ssh
        ;;
    legitimate2)
        echo -e "${BLUE}Connecting to legitimate base station #2 VM...${NC}"
        cd legitimate2 && vagrant ssh
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
