#!/bin/bash
set -e

BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  PRD Implementor — Uninstaller${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

CLAUDE_DIR="$HOME/.claude"

# Check for existing task data
if [ -d "$CLAUDE_DIR/tasks" ] && [ "$(ls -A "$CLAUDE_DIR/tasks" 2>/dev/null)" ]; then
    echo -e "${YELLOW}⚠ Warning: You have task data in ~/.claude/tasks/${NC}"
    echo "  Sessions found:"
    for dir in "$CLAUDE_DIR/tasks"/*/; do
        [ -d "$dir" ] && echo "    - $(basename "$dir")"
    done
    echo ""
    read -p "  Delete task data too? (y/N): " delete_tasks
    if [[ "$delete_tasks" =~ ^[Yy]$ ]]; then
        rm -rf "$CLAUDE_DIR/tasks"
        echo -e "  ${GREEN}✓${NC} Task data deleted"
    else
        echo -e "  ${BLUE}→${NC} Task data preserved"
    fi
fi

# Remove agent
[ -f "$CLAUDE_DIR/agents/prd-implementor.md" ] && rm "$CLAUDE_DIR/agents/prd-implementor.md" && echo -e "  ${GREEN}✓${NC} Removed agent"

# Remove skills
for skill in prd-plan prd-execute prd-status; do
    [ -d "$CLAUDE_DIR/skills/$skill" ] && rm -rf "$CLAUDE_DIR/skills/$skill" && echo -e "  ${GREEN}✓${NC} Removed skill: $skill"
done

echo ""
echo -e "${GREEN}Uninstall complete.${NC}"
echo ""
