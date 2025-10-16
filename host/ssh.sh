#!/bin/bash
# False Base Station Attack Infrastructure - Centralized Management
# Usage: ./ssh.sh [legitimate|false]

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
    echo "Usage: $0 [legitimate|false]"
    echo ""
    echo "Commands:"
    echo "  legitimate    SSH into legitimate base station VM"
    echo "  false         SSH into false base station VM"
    echo "  help          Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0 legitimate    # SSH into legitimate BS"
    echo "  $0 false         # SSH into false BS"
}

case "$1" in
    legitimate)
        echo -e "${BLUE}Connecting to legitimate base station VM...${NC}"
        cd legitimate && vagrant ssh
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
