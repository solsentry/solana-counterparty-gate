---
description: "Resolve a Solana program or wallet to its deployer and return a formatted operator risk verdict before you CPI/compose."
---

You are running a **counterparty gate** check. The user passed a program ID or
wallet (`$ARGUMENTS`). Goal: a clear go / caution / no-go verdict on the operator
behind it, before they integrate.

Load `skill/counterparty.md` and `skill/interpreting-scores.md` for the rules.

## Steps

1. **Classify the input.**
   - 32–44 char base58 that is a **program** → resolve to its deployer/upgrade
     authority wallet first (operators are wallets, not program IDs).
   - A **wallet** → use directly.

2. **Resolve program → deployer** (if a program):
   ```bash
   # Fetch the program's upgrade authority via RPC, or query SolSentry if indexed:
   curl -s https://api.solsentry.app/v1/operator/<deployer_wallet> | jq
   ```

3. **Score the operator:**
   ```bash
   curl -s https://api.solsentry.app/v1/operator/<wallet> \
     | jq '{risk_level, confirmed_rugs, total_tokens, rug_rate_pct, patterns, tags}'
   ```
   (Or MCP: `check_operator(wallet)`.)

4. **Render the verdict** using the output guidance in `counterparty.md`:
   - `CRITICAL`/`HIGH` → ⚠️ warn, show counts pulled live, suggest immutable-program
     check / alternative / circuit breaker.
   - `CLEAN` → ✓ no rug signal; standard CPI validation still applies.
   - `UNKNOWN` → ⓘ not tracked; absence ≠ safe.

## Rules

- Pull every number live; never reuse a number from any doc.
- Offer the per-mint audit trail: `/v1/predictions/{mint}`.
- Never output "safe" for `UNKNOWN`; never headline a `LOW` tier.
- One-line verdict first, then the supporting detail.
