#!/bin/bash
set -e

# ═══════════════════════════════════════════════════
#  PRD Implementor — Installer
#  Installs agent, skills, and commands for Claude Code
# ═══════════════════════════════════════════════════

BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color
CHECK="✓"
ARROW="→"

echo ""
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo -e "${BLUE}  PRD Implementor — Installer${NC}"
echo -e "${BLUE}═══════════════════════════════════════════${NC}"
echo ""

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Target directories
CLAUDE_DIR="$HOME/.claude"
AGENTS_DIR="$CLAUDE_DIR/agents"
SKILLS_DIR="$CLAUDE_DIR/skills"
TASKS_DIR="$CLAUDE_DIR/tasks"

# Create directories
echo -e "${ARROW} Creating directories..."
mkdir -p "$AGENTS_DIR"
mkdir -p "$SKILLS_DIR/prd-plan"
mkdir -p "$SKILLS_DIR/prd-execute"
mkdir -p "$SKILLS_DIR/prd-status"
mkdir -p "$TASKS_DIR"
echo -e "  ${GREEN}${CHECK}${NC} Directories ready"

# Install agent
echo -e "${ARROW} Installing agent..."
cp "$SCRIPT_DIR/agents/prd-implementor.md" "$AGENTS_DIR/prd-implementor.md"
echo -e "  ${GREEN}${CHECK}${NC} Agent: prd-implementor"

# Install skills
echo -e "${ARROW} Installing skills..."
cp "$SCRIPT_DIR/skills/prd-plan/SKILL.md" "$SKILLS_DIR/prd-plan/SKILL.md"
echo -e "  ${GREEN}${CHECK}${NC} Skill: /prd-plan"

cp "$SCRIPT_DIR/skills/prd-execute/SKILL.md" "$SKILLS_DIR/prd-execute/SKILL.md"
echo -e "  ${GREEN}${CHECK}${NC} Skill: /prd-execute"

cp "$SCRIPT_DIR/skills/prd-status/SKILL.md" "$SKILLS_DIR/prd-status/SKILL.md"
echo -e "  ${GREEN}${CHECK}${NC} Skill: /prd-status"

# Summary
echo ""
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo -e "${GREEN}  Installation complete!${NC}"
echo -e "${GREEN}═══════════════════════════════════════════${NC}"
echo ""
echo "  Installed to: $CLAUDE_DIR"
echo ""
echo "  Files:"
echo "    $AGENTS_DIR/prd-implementor.md"
echo "    $SKILLS_DIR/prd-plan/SKILL.md"
echo "    $SKILLS_DIR/prd-execute/SKILL.md"
echo "    $SKILLS_DIR/prd-status/SKILL.md"
echo ""
echo "  Usage:"
echo -e "    ${YELLOW}/prd-plan /path/to/prd.md${NC}    — Plan tasks from a PRD"
echo -e "    ${YELLOW}/prd-execute session-id${NC}       — Execute next task"
echo -e "    ${YELLOW}/prd-status${NC}                   — Check all sessions"
echo -e "    ${YELLOW}/prd-status session-id${NC}        — Check specific session"
echo ""
echo "  Tasks are stored in: $TASKS_DIR"
echo ""
