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
| 2 | `GET /v1/drain-trace/{wallet}` | Outflow trace: `hops[]` + `endpoints[]` |
| 3 | `GET /v1/operator/{wallet}/timeline` | Chronological activity history |
| 4 | `GET /v1/clusters` + `/v1/cluster/{id}` | Was the suspect coordinated with others? |

## Drain-trace

Follows outflows from the wallet, hop by hop:

```bash
curl -s https://api.solsentry.app/v1/drain-trace/<wallet> \
  | jq '{result_status, hop_count, total_sol_drained, reached_cex, reached_mixer, unknown_reasons, note,
         hops: (.hops | map({hop_number, from, to, amount_sol, asset, tx_signature, timestamp, destination_label, destination_category})),
         endpoints: (.endpoints | map({wallet, label, category, hop}))}'
```

| Field | Meaning |
|---|---|
| `hops[]` | Each transfer followed: `from`, `to`, `amount_sol`, `asset`, `tx_signature`, `timestamp`, `destination_label` / `destination_category` |
| `endpoints[]` | Where the trace stopped: `wallet`, `label`, `category`, `hop` |
| `reached_cex` / `reached_mixer` | Whether any endpoint was classified as an exchange / mixer |
| `result_status` / `unknown_reasons` / `note` | How complete the trace is — a `partial` or empty trace is **not** a clean result |

**Access:** metered. An anonymous caller gets one trace per UTC day; after that
the route answers `429` with `"error": "credit_quota_exceeded"` and a
`retry_after` in seconds. Per-route costs: `GET /v1/pricing`.

## Workflow

1. Confirm the suspect: `check_operator(X)` → `CRITICAL`/`HIGH` = known operator
   (expected behavior); `UNKNOWN` = newer wallet, more to investigate.
2. Trace the flow: `GET /v1/drain-trace/X` → read `endpoints[]` (`label`, `category`)
   and `reached_cex` / `reached_mixer`.
3. Identify accomplices: `check_operator()` each hop's `to` wallet — are any
   themselves flagged operators?
4. Cluster: if 2+ hop wallets are flagged, `GET /v1/clusters` to see if they're
   already a known group.
5. Output: a chain of evidence for an incident report or chain-analyst handoff.

## Output guidance

- **Reproducible** — every claim cites an `address`, `tx_signature`, or `cluster_id`.
- **Timestamped** — use the timestamps the API returns, not "today".
- **Scoped** — say "trace went cold at hop 7", not "this is the full picture".
- **Action-oriented** — end with what the user can do now (file with the CEX,
  contact bridge ops, public disclosure).

## Pitfall

Drain-trace shows **on-chain flow only**. It does not see CEX internal
(off-chain) book transfers, and `result_status` / `unknown_reasons` say what it
did not read or resolve. Treat the trace as evidence of what flowed where —
**not** proof of who controls a destination.
