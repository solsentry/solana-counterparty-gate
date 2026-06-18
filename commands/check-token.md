---
description: "Return a formatted risk verdict for a Solana token mint, including the deployer's operator risk."
---

You are checking a Solana token mint (`$ARGUMENTS`) before the user integrates,
buys, or lists it. Load `skill/threat-intel.md` and `skill/interpreting-scores.md`.

## Steps

1. **Score the mint:**
   ```bash
   curl -s https://api.solsentry.app/v1/token/<mint> \
     | jq '{risk_level, risk_score, flags, deployer, deployer_risk_level, outcome}'
   ```
   (Or MCP: `check_token(mint)`.)

2. **Always pivot to the deployer** — the operator-level signal is the
   differentiator. If `deployer_risk_level` is `HIGH`/`CRITICAL`, surface it:
   ```bash
   curl -s https://api.solsentry.app/v1/operator/<deployer> \
     | jq '{risk_level, confirmed_rugs, total_tokens, rug_rate_pct}'
   ```

3. **Render the verdict:**
   - Lead with the mint's `risk_level`, then the deployer's.
   - Translate `flags` into plain language (see `interpreting-scores.md` / the
     flag glossary): mint authority live, holder concentration, LP not locked, etc.
   - `outcome: pending` means not yet resolved — say so; don't imply a final call.

## Rules

- Pull numbers live; cite `/v1/predictions/{mint}` for auditability.
- Treat `LOW` as not load-bearing; never render `UNKNOWN` as "safe".
- One-line verdict first, then detail.
