#!/usr/bin/env bash
#
# solana-counterparty-gate — standard installer
# Installs with recommended defaults. For custom options, use ./install-custom.sh
#
# Layout after install:
#   ~/.claude/skills/solana-counterparty-gate/   (this skill)
#   ~/.claude/skills/solana-dev/                 (core skill it extends)

set -e

GREEN='\033[0;32m'; YELLOW='\033[1;33m'; BLUE='\033[0;34m'; CYAN='\033[0;36m'; RED='\033[0;31m'; WHITE='\033[1;37m'; NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SOURCE_DIR="$SCRIPT_DIR/skill"

SKILLS_DIR="$HOME/.claude/skills"
SKILL_NAME="solana-counterparty-gate"
CORE_SKILL_NAME="solana-dev"
SKILL_PATH="$SKILLS_DIR/$SKILL_NAME"
CORE_SKILL_PATH="$SKILLS_DIR/$CORE_SKILL_NAME"
CORE_REPO="https://github.com/solana-foundation/solana-dev-skill.git"

print_help() {
  echo "solana-counterparty-gate — standard installer"
  echo ""
  echo "Usage: ./install.sh [OPTIONS]"
  echo ""
  echo "Installs with recommended defaults:"
  echo "  - Location: ~/.claude/skills/"
  echo "  - Installs the core solana-dev skill if missing, then this skill"
  echo ""
  echo "Options:"
  echo "  -y, --yes    Skip confirmation prompt"
  echo "  -h, --help   Show this help"
  echo ""
  echo "For custom locations / project install, use: ./install-custom.sh"
}

SKIP_CONFIRM=false
while [[ $# -gt 0 ]]; do
  case $1 in
    -y|--yes) SKIP_CONFIRM=true; shift ;;
    -h|--help) print_help; exit 0 ;;
    *) echo "Unknown option: $1"; echo "Use --help for usage."; exit 1 ;;
  esac
done

echo ""
echo -e "${WHITE}SolSentry — Counterparty Gate skill${NC}"
echo -e "Clean code ≠ clean partner. Check the operator before the CPI."
echo ""
echo -e "This will install:"
echo -e "  ${BLUE}•${NC} $SKILL_NAME  → ${CYAN}$SKILL_PATH${NC}"
echo -e "  ${BLUE}•${NC} $CORE_SKILL_NAME (core, if missing)  → ${CYAN}$CORE_SKILL_PATH${NC}"
echo ""

if [ "$SKIP_CONFIRM" = false ]; then
  read -p "Proceed? [Y/n] " -n 1 -r; echo
  if [[ $REPLY =~ ^[Nn]$ ]]; then echo -e "${YELLOW}Cancelled.${NC}"; exit 0; fi
fi
echo ""

mkdir -p "$SKILLS_DIR"

# [1/2] core skill
echo -e "${CYAN}[1/2]${NC} Core skill ($CORE_SKILL_NAME)..."
if [ -d "$CORE_SKILL_PATH" ] && [ -f "$CORE_SKILL_PATH/SKILL.md" ]; then
  echo -e "  ${GREEN}✓${NC} already present, leaving as-is"
else
  tmp="$(mktemp -d)"
  if git clone --depth 1 --quiet "$CORE_REPO" "$tmp" 2>/dev/null; then
    rm -rf "$CORE_SKILL_PATH"; cp -r "$tmp/skill" "$CORE_SKILL_PATH"; rm -rf "$tmp"
    echo -e "  ${GREEN}✓${NC} installed to $CORE_SKILL_PATH"
  else
    rm -rf "$tmp"
    echo -e "  ${YELLOW}!${NC} could not clone core skill; this skill works standalone but"
    echo -e "    program-dev references will be dangling. Install manually: $CORE_REPO"
  fi
fi

# [2/2] this skill
echo -e "${CYAN}[2/2]${NC} This skill ($SKILL_NAME)..."
if [ ! -f "$SOURCE_DIR/SKILL.md" ]; then
  echo -e "  ${RED}✗${NC} $SOURCE_DIR/SKILL.md not found — run from the repo root."; exit 1
fi
rm -rf "$SKILL_PATH"; mkdir -p "$SKILL_PATH"
for item in "$SOURCE_DIR"/*; do
  base="$(basename "$item")"
  [ "$base" = "$CORE_SKILL_NAME" ] && continue   # skip vendored core submodule if present
  cp -r "$item" "$SKILL_PATH/"
done
echo -e "  ${GREEN}✓${NC} installed to $SKILL_PATH"

echo ""
echo -e "${GREEN}Done.${NC} Try asking your agent:"
echo -e "  ${BLUE}•${NC} \"I'm about to CPI into program <id> — is its deployer safe?\""
echo -e "  ${BLUE}•${NC} \"Check this token mint before I integrate it: <mint>\""
echo -e "  ${BLUE}•${NC} \"/check-counterparty <program|wallet>\""
echo ""
echo -e "Optional — copy commands/agents into a project:"
echo -e "  cp -r $SCRIPT_DIR/commands /path/to/project/.claude/commands/"
echo -e "  cp -r $SCRIPT_DIR/agents   /path/to/project/.claude/agents/"
echo ""
echo -e "${YELLOW}Powered by SolSentry · api.solsentry.app${NC}"
echo ""
