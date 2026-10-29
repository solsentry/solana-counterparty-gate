#!/usr/bin/env bash
#
# smoke.sh — verify that every API route this skill documents answers with the
# documented method, status and schema. No API key required (read endpoints).
#
# Usage:  bash tests/smoke.sh
# Env:    SOLSENTRY_API_URL  (default https://api.solsentry.app)
#
# Exit 0 = all checks passed. Exit 1 = a check failed (wrong status, missing key,
# or an address that could not be derived — a route is never silently skipped).
# No hero addresses are hardcoded: the mint, wallet and cluster under test are
# derived live from the API's own output, so this file carries no copy claims.

set -uo pipefail

API="${SOLSENTRY_API_URL:-https://api.solsentry.app}"
GREEN='\033[0;32m'; RED='\033[0;31m'; NC='\033[0m'
FAILS=0
TOTAL=12

need() { command -v "$1" >/dev/null 2>&1 || { echo -e "${RED}✗ missing dependency: $1${NC}"; exit 1; }; }
need curl; need jq

pass() { echo -e "  ${GREEN}✓${NC} $1"; }
fail() { echo -e "  ${RED}✗${NC} $1"; FAILS=$((FAILS+1)); }

# call METHOD PATH [JSON_BODY] → sets CODE and BODY
call() {
  local method="$1" path="$2" data="${3:-}" out
  if [ -n "$data" ]; then
    out="$(curl -s -m 120 -w $'\n%{http_code}' -X "$method" -H 'content-type: application/json' -d "$data" "$API$path")"
  else
    out="$(curl -s -m 120 -w $'\n%{http_code}' -X "$method" "$API$path")"
  fi
  CODE="$(printf '%s' "$out" | tail -n1)"
  BODY="$(printf '%s' "$out" | sed '$d')"
}
# presence check via "!= null" so boolean-false fields (e.g. suspect:false) still pass
has() { [ -n "$1" ] && printf '%s' "$1" | jq -e "$2 != null" >/dev/null 2>&1; }
fields() { local body="$1"; shift; for f in "$@"; do if has "$body" "$f"; then pass "field $f"; else fail "field $f MISSING"; fi; done; }
# check N LABEL METHOD PATH EXPECTED_CODE [JSON_BODY] -- KEY...
check() {
  local n="$1" label="$2" method="$3" path="$4" want="$5" data=""; shift 5
  if [ "${1:-}" != "--" ]; then data="$1"; shift; fi
  shift
  echo "[$n/$TOTAL] $method $label"
  call "$method" "$path" "$data"
  if [ "$CODE" = "$want" ]; then pass "$CODE"; fields "$BODY" "$@"
  else fail "expected $want, got $CODE"; BODY=""; fi
  echo ""
}
not_run() { echo "[$1/$TOTAL] $2"; fail "not run: $3"; echo ""; }
# Metered routes (credit cost in /v1/pricing) answer 429 credit_quota_exceeded
# once the anonymous allowance is spent; that is the documented answer, so it passes.
check_metered() {
  local n="$1" label="$2" path="$3"; shift 4
  echo "[$n/$TOTAL] GET $label (metered)"
  call GET "$path"
  if [ "$CODE" = "200" ]; then pass "200"; fields "$BODY" "$@"
  elif [ "$CODE" = "429" ] && printf '%s' "$BODY" | jq -e '.error == "credit_quota_exceeded"' >/dev/null 2>&1; then
    pass "429 credit_quota_exceeded (anonymous allowance spent — documented)"
  else fail "expected 200 or 429 credit_quota_exceeded, got $CODE"; fi
  echo ""
}

echo "SolSentry counterparty-gate smoke test → $API"
echo ""

check 1 "/v1/stats" GET /v1/stats 200 -- .total_predictions .resolved .confirmed_rugs .confirmed_safe .runtime_hours .avg_resolve_latency_hours

# Derive a live mint from the most recent alert.
check 2 "/v1/alerts/recent?limit=1" GET '/v1/alerts/recent?limit=1' 200 -- .alerts
MINT="$(printf '%s' "$BODY" | jq -r '.alerts[0].mint // empty' 2>/dev/null)"
[ -n "$MINT" ] && pass "derived mint" || fail "no mint in alerts"

# Derive a live cluster id, and a fallback wallet, from the cluster list.
check 3 "/v1/clusters?limit=1" GET '/v1/clusters?limit=1' 200 -- .clusters .total_clusters
CLUSTER_ID="$(printf '%s' "$BODY" | jq -r '.clusters[0].cluster_id // empty' 2>/dev/null)"
CLUSTER_OP="$(printf '%s' "$BODY" | jq -r '.clusters[0].operators[0] // empty' 2>/dev/null)"
[ -n "$CLUSTER_ID" ] && pass "derived cluster_id" || fail "no cluster_id in clusters"

if [ -n "$CLUSTER_ID" ]; then
  check_metered 4 "/v1/cluster/{cluster_id}" "/v1/cluster/$CLUSTER_ID" -- .members .tags .associated_tokens
else not_run 4 "GET /v1/cluster/{cluster_id}" "no cluster_id"; fi

# The token's dev_wallet is the wallet under test; fall back to a cluster operator.
WALLET=""
if [ -n "$MINT" ]; then
  check 5 "/v1/token/{mint}" GET "/v1/token/$MINT" 200 -- .risk_level .risk_score .flags .final_outcome
  WALLET="$(printf '%s' "$BODY" | jq -r '.dev_wallet // empty' 2>/dev/null)"
  check 6 "/v1/predictions/{mint}" GET "/v1/predictions/$MINT" 200 -- .predictions .summary
else
  not_run 5 "GET /v1/token/{mint}" "no mint"; not_run 6 "GET /v1/predictions/{mint}" "no mint"
fi
[ -n "$WALLET" ] || WALLET="$CLUSTER_OP"

if [ -n "$WALLET" ]; then
  check 7 "/v1/operator/{wallet}" GET "/v1/operator/$WALLET" 200 -- .known .risk_level .risk_label .confirmed_rugs .total_tokens .rug_rate_pct
  check_metered 8 "/v1/operator/{wallet}/timeline" "/v1/operator/$WALLET/timeline" -- .first_seen .last_seen .total_tokens_in_window .tokens
  check_metered 9 "/v1/drain-trace/{wallet}" "/v1/drain-trace/$WALLET" -- .hops .endpoints .result_status
  check 10 "/v1/lookalike-check?destination=…&contacts=…" GET "/v1/lookalike-check?destination=$WALLET&contacts=$WALLET" 200 -- .suspect .contacts_checked .findings
else
  for n in 7 8 9 10; do not_run "$n" "wallet routes" "no wallet derived"; done
fi

# tx-preview: both documented request forms. A tx_base64 that is not a
# transaction must come back as an inconclusive decode, never as a clean pass.
check 11 "/v1/tx-preview (parsed_tx)" POST /v1/tx-preview 200 '{"parsed_tx":{"accounts":[],"instructions":[]}}' -- .verdict .decode_ok .detectors_run
check 12 "/v1/tx-preview (tx_base64, not a transaction)" POST /v1/tx-preview 200 '{"tx_base64":"bm90LWEtdHg="}' -- .verdict .findings
if [ -n "$BODY" ]; then
  if printf '%s' "$BODY" | jq -e '.decode_ok == false' >/dev/null 2>&1; then pass "decode_ok false"; else fail "decode_ok is not false"; fi
fi
echo ""

# Summary
if [ "$FAILS" -eq 0 ]; then echo -e "${GREEN}All smoke checks passed.${NC}"; exit 0
else echo -e "${RED}$FAILS check(s) failed.${NC}"; exit 1; fi
