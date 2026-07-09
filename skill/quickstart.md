# Quickstart — 60 seconds to a verdict

Two ways to use this skill: the MCP server (zero-install via `npx`) or plain
REST (any agent, any language, no dependency). Both hit the same live backend
at `https://api.solsentry.app`. **No API key is required for read endpoints.**

## Option A — MCP (recommended for Claude Code / agents)

```jsonc
// .mcp.json (or Claude Code MCP config)
{
  "mcpServers": {
    "solsentry": {
      "command": "npx",
      "args": ["-y", "@solsentry/mcp"]
    }
  }
}
```

Then the four tools are available to the agent:

- `check_operator(wallet_address)` — is this deployer a rug operator?
- `check_token(mint_address)` — is this mint risky?
- `get_network_stats()` — system-wide live stats
- `explain_risk(address)` — plain-English summary

Optional env (defaults are fine for reads):

```bash
SOLSENTRY_API_URL=https://api.solsentry.app   # override base URL
SOLSENTRY_API_KEY=...                          # only needed for paid endpoints
```

## Option B — REST (no install)

One real call, copy-paste runnable right now:

```bash
# System is live? Pull fresh stats (always verify numbers here, never trust a doc)
curl -s https://api.solsentry.app/v1/stats | jq '{accuracy_pct, critical_precision_pct, confirmed_rugs, runtime_hours}'
```

Check a counterparty's deployer wallet:

```bash
# Replace <WALLET> with the deployer you resolved (see counterparty.md)
curl -s https://api.solsentry.app/v1/operator/<WALLET> \
  | jq '{risk_level, risk_label, confirmed_rugs, total_tokens, rug_rate_pct, patterns}'
```

Check a token mint:

```bash
curl -s https://api.solsentry.app/v1/token/<MINT> \
  | jq '{risk_level, risk_score, flags, deployer, deployer_risk_level, outcome}'
```

Audit any single verdict per-mint (the honesty contract — every score is checkable):

```bash
curl -s https://api.solsentry.app/v1/predictions/<MINT> | jq
```

## Endpoint map

| Endpoint | Returns |
|---|---|
| `GET /v1/stats` | System-wide live metrics (verify cited numbers here) |
| `GET /v1/operator/{wallet}` | Operator (deployer) risk profile |
| `GET /v1/token/{mint}` | Token mint risk profile |
| `GET /v1/predictions/{mint}` | Per-mint prediction + outcome (auditable) |
| `GET /v1/lookalike-check?...` | Address-poisoning / vanity lookalike check (see `tx-preview.md`) |
| `POST /v1/tx-preview` | Pre-sign risk preview of a transaction (see `tx-preview.md`) |
| `GET /v1/drain-trace/{wallet}` | Post-incident fund-flow trace (see `forensics.md`; x402-paid) |

## Verify it works

```bash
bash tests/smoke.sh
```

Hits the live endpoints, asserts `200` + key fields present. If it's green, the
skill is ready. Full reference for each task lives in the `skill/*.md` files —
load only the one matching your current task (see `SKILL.md`).
