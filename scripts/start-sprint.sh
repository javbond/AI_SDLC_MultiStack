#!/bin/bash
# scripts/start-sprint.sh — Launch Claude Code for sprint execution
# Usage: bash scripts/start-sprint.sh [--skip-permissions|-s] [sprint-number]
#
# Options:
#   --skip-permissions, -s  Launch with --dangerously-skip-permissions (no tool prompts)
#   [sprint-number]         Auto-invoke sprint planning for this sprint number
#
# Examples:
#   bash scripts/start-sprint.sh                  # Interactive mode (normal)
#   bash scripts/start-sprint.sh -s               # Interactive mode (skip prompts)
#   bash scripts/start-sprint.sh -s 3             # Sprint 3, skip prompts
#   bash scripts/start-sprint.sh 2                # Sprint 2, normal prompts
#
# This script is a shortcut for sprint-focused development sessions.
# It launches Claude Code with Agent Teams and optionally starts sprint planning.

set -e

PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"

# Parse arguments
SKIP_PERMISSIONS=false
SPRINT_NUMBER=""

for arg in "$@"; do
  case "$arg" in
    --skip-permissions|-s)
      SKIP_PERMISSIONS=true
      ;;
    [0-9]*)
      SPRINT_NUMBER="$arg"
      ;;
  esac
done

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

echo -e "${BLUE}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│          AI-NATIVE SDLC FACTORY — Sprint Launcher        │${NC}"
echo -e "${BLUE}└──────────────────────────────────────────────────────────┘${NC}"
echo ""

# Show permission mode
if [ "$SKIP_PERMISSIONS" = true ]; then
  echo -e "  ${CYAN}Permission Mode: SKIP ALL (--dangerously-skip-permissions)${NC}"
else
  echo -e "  ${GREEN}Permission Mode: PROMPT (default — use -s to skip)${NC}"
fi
echo ""

# Enable agent teams
export CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1

# Verify prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

if ! command -v claude &>/dev/null; then
  echo -e "${RED}✗ Claude Code CLI not found. Install: npm install -g @anthropic-ai/claude-code${NC}"
  exit 1
fi
echo -e "${GREEN}✓ Claude Code CLI found${NC}"

if command -v tmux &>/dev/null; then
  echo -e "${GREEN}✓ tmux found — split-pane mode available${NC}"
  TEAMMATE_MODE="tmux"
else
  echo -e "${YELLOW}⚠ tmux not found — using in-process mode${NC}"
  TEAMMATE_MODE="in-process"
fi

# Check agent definitions exist
AGENT_COUNT=$(ls "$PROJECT_ROOT/.claude/agents/"*.md 2>/dev/null | wc -l | tr -d ' ')
if [ "$AGENT_COUNT" -eq 0 ]; then
  echo -e "${RED}✗ No agent definitions found. Run: bash scripts/setup-agents.sh${NC}"
  exit 1
fi
echo -e "${GREEN}✓ ${AGENT_COUNT} agent definitions found${NC}"

# Load project state
echo ""
if [ -f "$PROJECT_ROOT/.sdlc/state.json" ]; then
  CURRENT_PHASE=$(python3 -c "import json; print(json.load(open('$PROJECT_ROOT/.sdlc/state.json'))['currentPhase'])" 2>/dev/null || echo "unknown")
  PROJECT_NAME=$(python3 -c "import json; print(json.load(open('$PROJECT_ROOT/.sdlc/state.json'))['project'])" 2>/dev/null || echo "unknown")
  SPRINT_COUNT=$(python3 -c "import json; print(len(json.load(open('$PROJECT_ROOT/.sdlc/state.json')).get('sprints',[])))" 2>/dev/null || echo "0")
  echo -e "${GREEN}Project: ${PROJECT_NAME}${NC}"
  echo -e "${GREEN}Current Phase: ${CURRENT_PHASE}${NC}"
  echo -e "${GREEN}Sprints Completed: ${SPRINT_COUNT}${NC}"
else
  echo -e "${YELLOW}No project initialized. Run /sdlc init [project-name] first.${NC}"
  exit 1
fi

echo ""
echo -e "${BLUE}Sprint Commands:${NC}"
echo "  /scrum-sprint planning     — Plan the sprint"
echo "  /develop backend [story]   — Implement backend"
echo "  /develop frontend [story]  — Implement frontend"
echo "  /build-with-agent-team     — Parallel execution"
echo "  /test-suite unit           — Run unit tests"
echo "  /scrum-sprint review       — Sprint review"
echo ""

# Build claude command arguments
CLAUDE_ARGS=(--teammate-mode "$TEAMMATE_MODE")
if [ "$SKIP_PERMISSIONS" = true ]; then
  CLAUDE_ARGS+=(--dangerously-skip-permissions)
fi

# Launch Claude Code
if [ -n "$SPRINT_NUMBER" ]; then
  echo -e "${BLUE}Starting Sprint ${SPRINT_NUMBER}...${NC}"
  echo -e "${YELLOW}Launching Claude Code...${NC}"
  echo ""
  cd "$PROJECT_ROOT" && claude "${CLAUDE_ARGS[@]}" -p "/scrum-sprint planning"
else
  echo -e "${BLUE}Starting Sprint Session — Interactive Mode${NC}"
  echo -e "${YELLOW}Launching Claude Code...${NC}"
  echo ""
  cd "$PROJECT_ROOT" && claude "${CLAUDE_ARGS[@]}"
fi
