#!/bin/bash
# update-kit.sh — Update an existing project with the latest kit files
#
# Usage:
#   bash /path/to/ai-sdlc-factory/update-kit.sh /path/to/my-project
#
# What it updates (overwrites):
#   - .claude/agents/          (agent definitions)
#   - .claude/skills/          (skill definitions)
#   - .claude/rules/           (coding standards)
#   - .claude/hooks/           (agent team hooks)
#   - scripts/                 (automation scripts)
#   - CLAUDE.md                (project documentation)
#   - USAGE-GUIDE.md           (user guide)
#   - kit.json                 (version metadata)
#
# What it preserves (never touches):
#   - .sdlc/state.json         (project state)
#   - docs/                    (generated artifacts)
#   - docs/tech-refs/          (imported reference docs)
#   - backend/, frontend/      (source code)
#   - workspaces/              (additional tech stack code)
#   - .gitignore               (may have been customized)
#   - .claude/settings.local.json (may have custom permissions)
#   - .claude/rules/06-tech-stack-context.md (regenerated after update)

set -e

# --- Parse arguments ---
TARGET_DIR="${1:-}"

if [ -z "$TARGET_DIR" ]; then
  echo ""
  echo "Usage: bash update-kit.sh /path/to/my-project"
  echo ""
  echo "Updates kit infrastructure in an existing project"
  echo "while preserving project state, docs, and source code."
  exit 1
fi

if [ ! -d "$TARGET_DIR" ]; then
  echo "Error: Directory not found: $TARGET_DIR"
  exit 1
fi

# --- Resolve paths ---
KIT_DIR="$(cd "$(dirname "$0")" && pwd)"
TARGET_DIR="$(cd "$TARGET_DIR" && pwd)"

# --- Colors ---
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo ""
echo -e "${BLUE}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│       AI-NATIVE SDLC FACTORY — Kit Update                │${NC}"
echo -e "${BLUE}└──────────────────────────────────────────────────────────┘${NC}"
echo ""

# --- Version check ---
KIT_VERSION="unknown"
TARGET_VERSION="unknown"

if [ -f "$KIT_DIR/kit.json" ] && command -v python3 &>/dev/null; then
  KIT_VERSION=$(python3 -c "import json; print(json.load(open('$KIT_DIR/kit.json'))['version'])" 2>/dev/null || echo "unknown")
fi

if [ -f "$TARGET_DIR/kit.json" ] && command -v python3 &>/dev/null; then
  TARGET_VERSION=$(python3 -c "import json; print(json.load(open('$TARGET_DIR/kit.json'))['version'])" 2>/dev/null || echo "unknown")
fi

echo -e "  Kit source version:    ${GREEN}v${KIT_VERSION}${NC}"
echo -e "  Project kit version:   ${YELLOW}v${TARGET_VERSION}${NC}"
echo ""

if [ "$KIT_VERSION" = "$TARGET_VERSION" ] && [ "$KIT_VERSION" != "unknown" ]; then
  echo -e "${GREEN}Already up to date (v${KIT_VERSION}). No changes needed.${NC}"
  exit 0
fi

# --- Update kit infrastructure ---
echo -e "${YELLOW}Updating kit infrastructure...${NC}"
echo ""

# Agents
echo -e "  ${GREEN}Updating${NC} .claude/agents/ ..."
rm -rf "$TARGET_DIR/.claude/agents"
cp -r "$KIT_DIR/.claude/agents" "$TARGET_DIR/.claude/agents"

# Skills
echo -e "  ${GREEN}Updating${NC} .claude/skills/ ..."
rm -rf "$TARGET_DIR/.claude/skills"
cp -r "$KIT_DIR/.claude/skills" "$TARGET_DIR/.claude/skills"

# Rules
echo -e "  ${GREEN}Updating${NC} .claude/rules/ ..."
rm -rf "$TARGET_DIR/.claude/rules"
cp -r "$KIT_DIR/.claude/rules" "$TARGET_DIR/.claude/rules"

# Hooks
echo -e "  ${GREEN}Updating${NC} .claude/hooks/ ..."
rm -rf "$TARGET_DIR/.claude/hooks"
cp -r "$KIT_DIR/.claude/hooks" "$TARGET_DIR/.claude/hooks"

# Scripts (all 6)
echo -e "  ${GREEN}Updating${NC} scripts/ ..."
cp "$KIT_DIR/scripts/sdlc-gate-check.sh" "$TARGET_DIR/scripts/"
cp "$KIT_DIR/scripts/setup-agents.sh" "$TARGET_DIR/scripts/"
cp "$KIT_DIR/scripts/start-sdlc.sh" "$TARGET_DIR/scripts/"
cp "$KIT_DIR/scripts/generate-tech-context.sh" "$TARGET_DIR/scripts/" 2>/dev/null || true
cp "$KIT_DIR/scripts/extract-doc-text.sh" "$TARGET_DIR/scripts/" 2>/dev/null || true
cp "$KIT_DIR/scripts/analyze-doc.sh" "$TARGET_DIR/scripts/" 2>/dev/null || true

# Documentation
echo -e "  ${GREEN}Updating${NC} CLAUDE.md ..."
cp "$KIT_DIR/CLAUDE.md" "$TARGET_DIR/CLAUDE.md"

echo -e "  ${GREEN}Updating${NC} USAGE-GUIDE.md ..."
cp "$KIT_DIR/USAGE-GUIDE.md" "$TARGET_DIR/USAGE-GUIDE.md"

# Kit metadata
echo -e "  ${GREEN}Updating${NC} kit.json ..."
cp "$KIT_DIR/kit.json" "$TARGET_DIR/kit.json"

echo ""

# --- Regenerate 06-tech-stack-context.md ---
echo -e "  ${GREEN}Regenerating${NC} .claude/rules/06-tech-stack-context.md ..."
if [ -f "$TARGET_DIR/scripts/generate-tech-context.sh" ] && [ -f "$TARGET_DIR/.sdlc/state.json" ]; then
  (cd "$TARGET_DIR" && bash scripts/generate-tech-context.sh 2>/dev/null) || echo -e "  ${YELLOW}Warning: Could not regenerate tech-stack-context. Run manually: bash scripts/generate-tech-context.sh${NC}"
else
  echo -e "  ${YELLOW}Skipped: No state.json found (new project?)${NC}"
fi

echo ""

# --- Preserved files ---
echo -e "${YELLOW}Preserved (not modified):${NC}"
echo -e "  ${GREEN}✓${NC} .sdlc/state.json (project state)"
echo -e "  ${GREEN}✓${NC} .claude/settings.local.json (permissions)"
echo -e "  ${GREEN}✓${NC} .gitignore (may be customized)"
echo -e "  ${GREEN}✓${NC} docs/ (generated artifacts)"
echo -e "  ${GREEN}✓${NC} docs/tech-refs/ (imported reference docs)"
echo -e "  ${GREEN}✓${NC} backend/, frontend/ (source code)"
echo -e "  ${GREEN}✓${NC} workspaces/ (additional tech stack code)"
echo ""

# --- Clean up .DS_Store ---
find "$TARGET_DIR/.claude" -name '.DS_Store' -delete 2>/dev/null || true

# --- Summary ---
echo -e "${BLUE}┌──────────────────────────────────────────────────────────┐${NC}"
echo -e "${BLUE}│  Update Complete: v${TARGET_VERSION} → v${KIT_VERSION}${NC}"
echo -e "${BLUE}│                                                          │${NC}"
echo -e "${BLUE}│  Run ${GREEN}bash scripts/setup-agents.sh${BLUE} to reconfigure agents  │${NC}"
echo -e "${BLUE}│  06-tech-stack-context.md regenerated from state.json    │${NC}"
echo -e "${BLUE}└──────────────────────────────────────────────────────────┘${NC}"
echo ""
