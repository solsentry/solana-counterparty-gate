# Reference: forensics (post-incident)

Load this when the user reports something **already happened** — a drain, an
exploit, a suspicious flow — and needs a post-mortem trace. This is the reactive
counterpart to `counterparty.md` (which is preventive).

## When to use

- "My LP got drained" / "tokens disappeared from my vault"
- An exploit or hack is being documented
- Tracing where SOL went after a known rug event
- Building a public incident post-mortem

## Procedure

| Step | Call | Purpose |
|---|---|---|
| 1 | `check_operator(suspect_wallet)` | Background on the wallet involved |
| 2 | `GET /v1/drain-trace/{wallet}` | SOL outflow trace (up to 10 hops) |
| 3 | `GET /v1/operator/{wallet}/timeline` | Chronological activity history |
| 4 | `GET /v1/clusters` + `/v1/cluster/{id}` | Was the suspect coordinated with others? |

## Drain-trace

Follows SOL outflows up to **10 hops**, classifying each:

- `cex` — known centralized-exchange deposit address
- `bridge` — cross-chain bridge entry
- `mixer` — privacy mixer
- `intermediate` — pass-through wallet (often single-use, bot-owned)
- `terminal` — trace endpoint (further movement not tracked)

```bash
curl https://api.solsentry.app/v1/drain-trace/<wallet>
# Free for verified victims (the wallet that received the SolSentry rug alert).
# Otherwise paid via x402 micropayment — send X-PAYMENT header (see SolSentry x402 docs).
```

## Workflow

1. Confirm the suspect: `check_operator(X)` → `CRITICAL`/`HIGH` = known operator
   (expected behavior); `UNKNOWN` = newer wallet, more to investigate.
2. Trace the SOL: `GET /v1/drain-trace/X` → map endpoints to CEX deposits / bridge entries.
3. Identify accomplices: `check_operator()` each `intermediate` hop — are any
   themselves flagged operators?
4. Cluster: if 2+ intermediates are flagged, `GET /v1/clusters` to see if they're
   already a known group.
5. Output: a chain of evidence for an incident report or chain-analyst handoff.

## Output guidance

- **Reproducible** — every claim cites an `address`, `tx_signature`, or `cluster_id`.
- **Timestamped** — use the timestamps the API returns, not "today".
- **Scoped** — say "trace went cold at hop 7", not "this is the full picture".
- **Action-oriented** — end with what the user can do now (file with the CEX,
  contact bridge ops, public disclosure).

## Pitfall

Drain-trace shows **on-chain SOL flow only**. It does not see wrapped tokens
unwrapped elsewhere, CEX internal (off-chain) book transfers, or wallets the
scanner has not yet observed. Treat the trace as evidence of what flowed where —
**not** proof of who controls a destination.
