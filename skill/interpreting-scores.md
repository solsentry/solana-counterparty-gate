# Reference: interpreting-scores (read this before you quote a number)

This reference exists so the agent reads SolSentry output **honestly** — not
over-claiming, not under-warning. Treating a score correctly is a feature, not a
footnote.

## The tiers (and what each actually licenses you to say)

| Level | Operator criteria | Token criteria | What you may say |
|---|---|---|---|
| `CRITICAL` | 10+ confirmed rugs | score ≥ 80, or token confirmed as rug | "do not compose / do not sign" |
| `HIGH` | 5+ confirmed rugs | score ≥ 60 | "treat as unsafe; prefer an alternative" |
| `MEDIUM` | 2+ confirmed rugs | score ≥ 50 | "elevated — surface it, proceed with explicit caution" |
| `CLEAN` | no rugs, has tracked tokens | — | "no rug signal" (not "safe") |
| `UNKNOWN` | not in database | not yet scanned | "no history found — absence is not safety" |

Only the levels in this table are verdicts. Cite `CRITICAL` / `HIGH` (and
`MEDIUM` when needed); if a response carries any other level, do not headline it
— fold it into "treat as cautious-`UNKNOWN`".

## How to state the track record (no percentages)

Do not quote a precision or accuracy percentage — not per tier, not blended.
Most new Solana launches die regardless of any flag, so a ratio quoted without
the base rate of the same universe and window overstates what the signal adds.
And never claim perfect precision or an error-free record (no detector is
perfect; claiming it invites disproof). State the track record as a count and point at the audit
trail:

> "Over N outcome-tracked predictions, each auditable per mint at
> `/v1/predictions/{mint}`."

Read N live from `GET /v1/stats` (`resolved`) on the day you cite it. Numbers
move as outcomes resolve; a number copied from a doc is already stale.

## `UNKNOWN` ≠ safe (the most common misread)

`UNKNOWN` means the wallet/mint was not found as a tracked deployer/scan — it is
**silence, not endorsement**. A fresh attacker wallet is `UNKNOWN` right up until
its first rug resolves. Standard validation (account ownership, signer checks,
reload-after-CPI, holder/LP inspection) applies regardless of tier.

## How a token score is built (so you can explain it)

- Base score from on-chain **flags** — mint/freeze authority, holder
  concentration, LP lock, bundle/coordination, metadata, lifecycle. Combinations
  are sub-additive (overlapping signals don't double-count).
- **Serial-deployer boost**: +15 if the deployer has ≥2 confirmed rugs, +25 if
  also classified serial. This is the operator-graph signal flowing into the
  token score — the thing bytecode tools can't see.
- Score floors: `CRITICAL` ≥ 80, `HIGH` ≥ 60, `MEDIUM` ≥ 50. Tokens with little data
  (<10 holders) carry a soft risk floor so "too new to tell" doesn't read as clean.

## Operator labels (`risk_label`)

Quote `risk_label` exactly as the API returns it, next to `confirmed_rugs` /
`total_tokens` (`rug_rate_pct` = confirmed_rugs / total_tokens). Do not derive a
label from `rug_rate_pct` yourself, and don't infer a label the API didn't give
you. A wallet with one or two tokens is too small a sample to call serial.

## Outcome timing (so you qualify "real-time" honestly)

A flagged token is watched before its outcome resolves:

- Fast-track ~6h (risk ≥ 80, or mint+freeze kept, or top holder ≥ 70%)
- Primary resolution otherwise — read the live average from `/v1/stats`
  (`avg_resolve_latency_hours`); it moves with the backlog
- Volume-dead (<$100 24h volume) resolves immediately

So: the **scan/lookup** is fast (sub-second; the API returns `latency_ms`), but
**outcome confirmation** takes hours to days. Say "sub-second response" or
"fast on-demand lookup" for the API; say "6h fast-track" plus the live
`avg_resolve_latency_hours` for outcomes. Never describe outcomes as instant.

## Why the rubric is public

The thresholds are published on purpose — a scoring system that hides its rubric
is a black box no serious integrator can adopt. Knowing `CRITICAL = 80` does not
let an attacker game it; the protected work is the *signal detection* (which
patterns map to which increments) and the evolutionary tuning, which stay
private. This is the open-core line: open rubric + open API, private engine.
