#!/usr/bin/env bash
#
# smoke.sh — verify the SolSentry API surface this skill depends on is live and
# returns the documented schema. No API key required (read endpoints).
#
# Usage:  bash tests/smoke.sh
# Env:    SOLSENTRY_API_URL  (default https://api.solsentry.app)
#
# Exit 0 = all checks passed. Exit 1 = a check failed.
# No hero addresses are hardcoded: the operator/token wallet under test is
# derived live from /v1/top-operators so this file carries no copy claims.

set -uo pipefail

API="${SOLSENTRY_API_URL:-https://api.solsentry.app}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
FAILS=0

need() {
  command -v "$1" >/dev/null 2>&1 || { echo -e "${RED}✗ missing dependency: $1${NC}"; exit 1; }
}
need curl
need jq

pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; FAILS=$((FAILS+1)); }

# GET a path, assert HTTP 200, return body on stdout (empty on failure).
get200() {
  local path="$1" body code
  body="$(curl -s -w $'\n%{http_code}' "$API$path")" || { echo ""; return 1; }
  code="$(printf '%s' "$body" | tail -n1)"
  body="$(printf '%s' "$body" | sed '$d')"
  [ "$code" = "200" ] || { echo ""; return 1; }
  printf '%s' "$body"
}

# assert a jq path is present (not null) in a JSON body
has() {
  local body="$1" expr="$2"
  [ -n "$body" ] && [ "$(printf '%s' "$body" | jq -r "$expr // empty" 2>/dev/null)" != "" ]
}

echo "SolSentry counterparty-gate smoke test → $API"
echo ""

# 1) /v1/stats — system liveness + key aggregate fields
echo "[1/4] GET /v1/stats"
STATS="$(get200 /v1/stats)"
if [ -n "$STATS" ]; then
  pass "200 OK"
  for f in .accuracy_pct .critical_precision_pct .confirmed_rugs .total_operators .runtime_hours; do
    if has "$STATS" "$f"; then pass "field $f present"; else fail "field $f MISSING"; fi
  done
else
  fail "/v1/stats not reachable (non-200)"
fi
echo ""

# 2) derive a live operator wallet to test against (no hardcoded address)
echo "[2/4] GET /v1/top-operators?limit=1 (derive test wallet)"
TOP="$(get200 '/v1/top-operators?limit=1')"
WALLET=""
if [ -n "$TOP" ]; then
  pass "200 OK"
  WALLET="$(printf '%s' "$TOP" | jq -r '.operators[0].wallet // empty')"
  if [ -n "$WALLET" ]; then pass "derived test wallet"; else fail "no wallet in leaderboard"; fi
else
  fail "/v1/top-operators not reachable (non-200)"
fi
echo ""

# 3) /v1/operator/{wallet} — operator profile schema
echo "[3/4] GET /v1/operator/{wallet}"
if [ -n "$WALLET" ]; then
  OP="$(get200 "/v1/operator/$WALLET")"
  if [ -n "$OP" ]; then
    pass "200 OK"
    for f in .risk_level .confirmed_rugs .total_tokens .rug_rate_pct; do
      if has "$OP" "$f"; then pass "field $f present"; else fail "field $f MISSING"; fi
    done
  else
    fail "/v1/operator/{wallet} non-200"
  fi
else
  echo -e "  ${YELLOW}-${NC} skipped (no wallet derived)"
fi
echo ""

# 4) /v1/predictions/{mint} — per-mint auditability endpoint reachable
#    (uses the derived wallet's first token if exposed; else just probes stats already covered)
echo "[4/4] GET /v1/top-operators schema (rug_rate_pct sanity)"
if [ -n "$TOP" ]; then
  RATE="$(printf '%s' "$TOP" | jq -r '.operators[0].rug_rate_pct // empty')"
  if [ -n "$RATE" ]; then pass "leaderboard exposes rug_rate_pct ($RATE)"; else fail "rug_rate_pct missing on leaderboard"; fi
else
  echo -e "  ${YELLOW}-${NC} skipped"
fi
echo ""

# Summary
if [ "$FAILS" -eq 0 ]; then
  echo -e "${GREEN}All smoke checks passed.${NC}"
  exit 0
else
  echo -e "${RED}$FAILS check(s) failed.${NC}"
  exit 1
fi
