# Reference: operator-history (cross-launch deploy history, in depth)

`check_operator` gives you the **verdict** on a wallet. This reference gives you
the **track record behind it** — the operator's full deploy timeline across many
launches over months, not a single launch window.

Why it matters: launch-window forensics (bundle/sniper analysis in the first
~48h of one token) tells you how *one* launch behaved. It cannot tell you that
the same operator quietly shipped, rugged, and rebranded across dozens of other
tokens before this one. That cross-launch history is the operator-graph signal —
and it's what separates "this launch looks coordinated" from "this is a serial
operator with a 1,600-launch rap sheet."

## The call

```bash
curl -s https://api.solsentry.app/v1/operator/<wallet>/timeline \
  | jq '{risk_level,first_seen,last_seen,total_tokens_in_window,confirmed_rugs_in_window,
          buckets_daily, sample: (.tokens[0:3] | map({mint,symbol,deployed_at,risk_level,final_outcome,time_to_rug_seconds,platform}))}'
```

### Fields

| Field | Meaning |
|---|---|
| `first_seen` / `last_seen` | Unix ts of the operator's earliest and latest observed deploy — the **span** of the track record (often months) |
| `total_tokens_in_window` / `confirmed_rugs_in_window` | Deploy volume and confirmed-rug count over the returned window |
| `buckets_daily` | Per-day deploy counts — surfaces cadence and burst patterns (the `fast_deployer` signature) |
| `tokens[]` | Each launch: `mint`, `symbol`, `deployed_at`, `risk_level`, `final_outcome`, `time_to_rug_seconds`, `platform` |

`time_to_rug_seconds` per launch is the depth a 48h window can't give you: it
lets you see whether the operator rugs in minutes or slow-bleeds over days, and
whether that behavior is consistent across launches (it usually is — operators
reuse playbooks).

## When to load this

- The verdict came back `CRITICAL`/`HIGH` and the user wants the **evidence**,
  not just the label, before deciding.
- Writing a counterparty report (`agents/counterparty-analyst.md`) that needs
  the operator's deploy cadence and rebrand pattern.
- Distinguishing a one-off bad launch from a **serial** operator — the timeline
  span (`first_seen` → `last_seen`) plus rug count across launches is the tell.

## How to read it (honestly)

- `buckets_daily` spikes + a wide `first_seen`→`last_seen` span + high
  `confirmed_rugs_in_window` = a serial operator with a sustained playbook, not a
  single unlucky launch.
- A short span with few tokens is **too small to label** — say so; don't infer
  "serial" from 2 launches (see `interpreting-scores.md` operator labels).
- `final_outcome` values include `pending` (watched, not yet resolved) and, on
  some launches, `nft_fp` (an early flag re-classified as a false positive) —
  both shown openly. The window is a snapshot; the operator-level aggregate
  (`/v1/operator/{wallet}`) is the headline count.

This is the difference between "deployer reputation as a concept" and a queryable
**rap sheet** with timestamps. The history already exists — you read it, you
don't reconstruct it hop by hop.
