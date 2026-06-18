#!/usr/bin/env bash
#
# solana-counterparty-gate — custom installer (full control)
# Usage: ./install-custom.sh [--project | --path <path>]
#
# Lets you choose the install location and whether to pull the core
# solana-dev skill. For the zero-question path, use ./install.sh

set -e

RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; WHITE='\033[1;37m'; NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skill"
SKILL_NAME="solana-counterparty-gate"
CORE_SKILL_NAME="solana-dev"
CORE_REPO="https://github.com/solana-foundation/solana-dev-skill.git"

PERSONAL_SKILLS_DIR="$HOME/.claude/skills"
PROJECT_SKILLS_DIR=".claude/skills"

INSTALL_BASE=""
SKILL_INSTALL_PATH=""
CORE_INSTALL_PATH=""
CORE_FOUND=""

print_help() {
  echo "solana-counterparty-gate — custom installer"
  echo ""
  echo "Usage: ./install-custom.sh [OPTIONS]"
  echo ""
  echo "Options:"
  echo "  --project      Install to current project (.claude/skills/)"
  echo "  --path PATH     Install to a custom base path"
  echo "  -h, --help      Show this help"
  echo ""
  echo "Interactive when no location flag is given."
}

prompt_location() {
  echo ""
  echo -e "${CYAN}Select install location${NC}"
  echo -e "  ${WHITE}[1]${NC} ${GREEN}Personal${NC}  (~/.claude/skills/) — all projects"
  echo -e "  ${WHITE}[2]${NC} ${GREEN}Project${NC}   (./.claude/skills/) — this project only"
  echo -e "  ${WHITE}[3]${NC} ${RED}Cancel${NC}"
  echo ""
  read -p "Option [1-3]: " choice
  case $choice in
    1) INSTALL_BASE="$PERSONAL_SKILLS_DIR" ;;
    2) INSTALL_BASE="$PROJECT_SKILLS_DIR" ;;
    3) echo -e "${YELLOW}Cancelled.${NC}"; exit 0 ;;
    *) echo -e "${RED}Invalid option.${NC}"; exit 1 ;;
  esac
}

find_core() {
  local locations=(
    "$PERSONAL_SKILLS_DIR/$CORE_SKILL_NAME"
    "$PROJECT_SKILLS_DIR/$CORE_SKILL_NAME"
    "$HOME/.claude/$CORE_SKILL_NAME"
  )
  for loc in "${locations[@]}"; do
    if [ -d "$loc" ] && [ -f "$loc/SKILL.md" ]; then CORE_FOUND="$loc"; return 0; fi
  done
  CORE_FOUND=""; return 1
}

install_core() {
  echo -e "${CYAN}━━━ Installing core solana-dev skill ━━━${NC}"
  mkdir -p "$CORE_INSTALL_PATH"
  local tmp; tmp="$(mktemp -d)"
  if git clone --depth 1 --quiet "$CORE_REPO" "$tmp" 2>/dev/null; then
    cp -r "$tmp/skill/"* "$CORE_INSTALL_PATH/"; rm -rf "$tmp"
    echo -e "${GREEN}✓${NC} core → $CORE_INSTALL_PATH"
  else
    rm -rf "$tmp"
    echo -e "${YELLOW}!${NC} clone failed — install manually: $CORE_REPO"
  fi
}

install_skill() {
  echo -e "${CYAN}━━━ Installing $SKILL_NAME ━━━${NC}"
  [ -f "$SOURCE_DIR/SKILL.md" ] || { echo -e "${RED}✗${NC} run from repo root (skill/SKILL.md missing)"; exit 1; }
  if [ -d "$SKILL_INSTALL_PATH" ]; then
    read -p "$SKILL_INSTALL_PATH exists. Overwrite? (y/N) " -n 1 -r; echo
    [[ $REPLY =~ ^[Yy]$ ]] || { echo -e "${YELLOW}Skipped.${NC}"; return 0; }
    rm -rf "$SKILL_INSTALL_PATH"
  fi
  mkdir -p "$SKILL_INSTALL_PATH"
  for item in "$SOURCE_DIR"/*; do
    base="$(basename "$item")"
    [ "$base" = "$CORE_SKILL_NAME" ] && continue
    cp -r "$item" "$SKILL_INSTALL_PATH/"
  done
  echo -e "${GREEN}✓${NC} skill → $SKILL_INSTALL_PATH"
}

# args
while [[ $# -gt 0 ]]; do
  case $1 in
    --project) INSTALL_BASE="$PROJECT_SKILLS_DIR"; shift ;;
    --path) INSTALL_BASE="$2"; shift 2 ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown option: $1"; exit 1 ;;
  esac
done

echo -e "${WHITE}SolSentry — Counterparty Gate (custom install)${NC}"
[ -z "$INSTALL_BASE" ] && prompt_location
SKILL_INSTALL_PATH="$INSTALL_BASE/$SKILL_NAME"
CORE_INSTALL_PATH="$INSTALL_BASE/$CORE_SKILL_NAME"

echo ""
echo -e "${CYAN}Checking for core solana-dev skill...${NC}"
if find_core; then
  echo -e "${GREEN}✓${NC} found at $CORE_FOUND"
else
  echo -e "${YELLOW}✗${NC} not found"
  read -p "Install core solana-dev too? (Y/n) " -n 1 -r; echo
  [[ $REPLY =~ ^[Nn]$ ]] || install_core
fi

install_skill

echo ""
echo -e "${YELLOW}Optional — project commands/agents:${NC}"
echo -e "  cp -r $SCRIPT_DIR/commands /path/to/project/.claude/commands/"
echo -e "  cp -r $SCRIPT_DIR/agents   /path/to/project/.claude/agents/"
echo ""
echo -e "${GREEN}Done.${NC} ${YELLOW}Powered by SolSentry · api.solsentry.app${NC}"
