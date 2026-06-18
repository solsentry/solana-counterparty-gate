#!/usr/bin/env bash
#
# smoke.sh — verify the SolSentry API surface this skill depends on is live and
# returns the documented schema. No API key required (read endpoints).
#
# Usage:  bash tests/smoke.sh
# Env:    SOLSENTRY_API_URL  (default https://api.solsentry.app)
#
# Exit 0 = all checks passed. Exit 1 = a check failed.
# No hero addresses are hardcoded: the wallet/mint under test are derived live
# (top-operators / alerts) so this file carries no copy claims of its own.

set -uo pipefail

API="${SOLSENTRY_API_URL:-https://api.solsentry.app}"
GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[1;33m'; NC='\033[0m'
FAILS=0

need() { command -v "$1" >/dev/null 2>&1 || { echo -e "${RED}✗ missing dependency: $1${NC}"; exit 1; }; }
need curl; need jq

pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; FAILS=$((FAILS+1)); }

# GET a path, assert HTTP 200, echo body (empty on failure).
get200() {
  local path="$1" body code
  body="$(curl -s -w $'\n%{http_code}' "$API$path")" || { echo ""; return 1; }
  code="$(printf '%s' "$body" | tail -n1)"
  body="$(printf '%s' "$body" | sed '$d')"
  [ "$code" = "200" ] || { echo ""; return 1; }
  printf '%s' "$body"
}
# presence check via "!= null" so boolean-false fields (e.g. suspect:false) still pass
has() { [ -n "$1" ] && printf '%s' "$1" | jq -e "$2 != null" >/dev/null 2>&1; }
fields() { local body="$1"; shift; for f in "$@"; do if has "$body" "$f"; then pass "field $f"; else fail "field $f MISSING"; fi; done; }

echo "SolSentry counterparty-gate smoke test → $API"
echo ""

# 1) /v1/stats
echo "[1/8] GET /v1/stats"
STATS="$(get200 /v1/stats)"
if [ -n "$STATS" ]; then pass "200 OK"; fields "$STATS" .accuracy_pct .critical_precision_pct .confirmed_rugs .runtime_hours
else fail "/v1/stats unreachable"; fi
echo ""

# 2) /v1/top-operators → derive a wallet
echo "[2/8] GET /v1/top-operators (derive wallet)"
TOP="$(get200 '/v1/top-operators?limit=1')"; WALLET=""
if [ -n "$TOP" ]; then pass "200 OK"; WALLET="$(printf '%s' "$TOP" | jq -r '.operators[0].wallet // empty')"
  [ -n "$WALLET" ] && pass "derived wallet" || fail "no wallet in leaderboard"
else fail "/v1/top-operators unreachable"; fi
echo ""

# 3) /v1/operator/{wallet}
echo "[3/8] GET /v1/operator/{wallet}"
if [ -n "$WALLET" ]; then OP="$(get200 "/v1/operator/$WALLET")"
  if [ -n "$OP" ]; then pass "200 OK"; fields "$OP" .risk_level .confirmed_rugs .total_tokens .rug_rate_pct; else fail "operator non-200"; fi
else echo -e "  ${YELLOW}-${NC} skipped (no wallet)"; fi
echo ""

# 4) /v1/alerts/recent → derive a mint
echo "[4/8] GET /v1/alerts/recent (derive mint)"
ALERTS="$(get200 '/v1/alerts/recent?limit=1')"; MINT=""
if [ -n "$ALERTS" ]; then pass "200 OK"; MINT="$(printf '%s' "$ALERTS" | jq -r '.alerts[0].mint // empty')"
  [ -n "$MINT" ] && pass "derived mint" || fail "no mint in alerts"
else fail "/v1/alerts/recent unreachable"; fi
echo ""

# 5) /v1/token/{mint}
echo "[5/8] GET /v1/token/{mint}"
if [ -n "$MINT" ]; then TOK="$(get200 "/v1/token/$MINT")"
  if [ -n "$TOK" ]; then pass "200 OK"; fields "$TOK" .risk_level .risk_score; else fail "token non-200"; fi
else echo -e "  ${YELLOW}-${NC} skipped (no mint)"; fi
echo ""

# 6) /v1/predictions/{mint} — the per-mint auditability endpoint
echo "[6/8] GET /v1/predictions/{mint}"
if [ -n "$MINT" ]; then PRED="$(get200 "/v1/predictions/$MINT")"
  [ -n "$PRED" ] && pass "200 OK (auditable per-mint)" || fail "predictions non-200"
else echo -e "  ${YELLOW}-${NC} skipped (no mint)"; fi
echo ""

# 7) /v1/lookalike-check
echo "[7/8] GET /v1/lookalike-check"
if [ -n "$WALLET" ]; then LK="$(get200 "/v1/lookalike-check?destination=$WALLET&contacts=$WALLET")"
  if [ -n "$LK" ]; then pass "200 OK"; fields "$LK" .suspect .contacts_checked; else fail "lookalike non-200"; fi
else echo -e "  ${YELLOW}-${NC} skipped (no wallet)"; fi
echo ""

# 8) POST /v1/tx-preview
echo "[8/8] POST /v1/tx-preview"
TXP="$(curl -s -w $'\n%{http_code}' -X POST -H 'content-type: application/json' \
  -d '{"parsed_tx":{"accounts":[],"instructions":[]}}' "$API/v1/tx-preview")"
TXCODE="$(printf '%s' "$TXP" | tail -n1)"; TXBODY="$(printf '%s' "$TXP" | sed '$d')"
if [ "$TXCODE" = "200" ]; then pass "200 OK"; fields "$TXBODY" .verdict .decode_ok .detectors_run
else fail "tx-preview non-200 (got $TXCODE)"; fi
echo ""

# Summary
if [ "$FAILS" -eq 0 ]; then echo -e "${GREEN}All smoke checks passed.${NC}"; exit 0
else echo -e "${RED}$FAILS check(s) failed.${NC}"; exit 1; fi
