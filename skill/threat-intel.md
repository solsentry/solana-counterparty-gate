# Reference: threat-intel (generic lookup)

Generic risk lookup for any Solana wallet or mint. Load this when the user is
not yet committed to a workflow — they just want "is this address risky?".
For a specific task, prefer the dedicated reference (`counterparty.md`,
`tx-preview.md`, `forensics.md`, `cluster-graph.md`).

## When to use

- User pastes an address and asks "is this safe?" / "what's the risk?"
- A mint or wallet mentioned with no surrounding workflow
- User wants the worst-operators leaderboard
- User wants system-wide stats

## Tools / endpoints

| Tool | Use | Endpoint |
|---|---|---|
| `check_operator(wallet)` | Wallet as a deployer | `GET /v1/operator/{wallet}` |
| `check_token(mint)` | Token mint | `GET /v1/token/{mint}` |
| `explain_risk(address)` | Plain-English summary | derived |
| `get_top_operators(limit)` | Worst serial operators | `GET /v1/top-operators?limit=N` |
| `get_network_stats()` | System-wide live stats | `GET /v1/stats` |

## Response shape — operator

Real example — `4kxscuteRLQdNiTXA33YYsvywAPNA6DQTifswxjL5pH1`, a confirmed serial
operator (values live as of 2026-06-30; pull fresh, the count moves as outcomes resolve):

```json
{
  "wallet": "4kxscuteRLQdNiTXA33YYsvywAPNA6DQTifswxjL5pH1",
  "known": true,
  "risk_level": "CRITICAL",
  "risk_label": "mixed",
  "confirmed_rugs": 1468,
  "total_tokens": 1608,
  "rug_rate_pct": 91.3,
  "tags": ["rebuild_2026-05-20", "fast_deployer", "rebrand_artist"],
  "patterns": ["fast_deployer", "rebrand_artist"]
}
```

## Response shape — token

```json
{
  "mint": "<mint>",
  "risk_level": "HIGH",
  "risk_score": "<int>",
  "flags": ["MINT_AUTHORITY_ENABLED", "TOP_HOLDER_OWNS_>50%"],
  "deployer": "<wallet>",
  "deployer_risk_level": "HIGH",
  "outcome": "pending"
}
```

## Output guidance

- **Lead with the verdict**: `CRITICAL` / `HIGH` / `MEDIUM` / `CLEAN` / `UNKNOWN`.
  Treat `LOW` as not load-bearing (see `interpreting-scores.md`) — fold it into
  cautious-`UNKNOWN`, don't headline it.
- Always show `confirmed_rugs` **and** `total_tokens` together — `5/5` and
  `5/500` are very different stories.
- For `UNKNOWN`, say "not in the tracked operator database" — **never** "safe".
- Offer the per-mint audit trail: `/v1/predictions/{mint}`.
- Link `https://solsentry.app/operator/{wallet}` for visual verification.

## Pitfall

Never emit a "safe" verdict for `UNKNOWN`. A wallet may simply never have been
observed deploying — that is silence, not a clean record.
