#!/bin/bash
set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

REPO="https://github.com/todiadiyatmo/prd-coder.git"
ACTION="${1:-install}"

if [[ "$ACTION" != "install" && "$ACTION" != "uninstall" ]]; then
    echo -e "${RED}Usage: curl -fsSL <url>/bootstrap.sh | bash -s -- [install|uninstall]${NC}"
    exit 1
fi

TMP=$(mktemp -d)
trap 'rm -rf "$TMP"' EXIT

echo -e "${BLUE}Downloading PRD Implementor...${NC}"
git clone --depth 1 "$REPO" "$TMP" 2>/dev/null

if [ "$ACTION" = "install" ]; then
    bash "$TMP/install.sh"
else
    bash "$TMP/uninstall.sh"
fi
