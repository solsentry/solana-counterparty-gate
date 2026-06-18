# Reference: interpreting-scores (read this before you quote a number)

This reference exists so the agent reads SolSentry output **honestly** — not
over-claiming, not under-warning. Treating a score correctly is a feature, not a
footnote.

## The tiers (and what each actually licenses you to say)

| Level | Operator criteria | Token criteria | What you may say |
|---|---|---|---|
| `CRITICAL` | 10+ confirmed rugs | token confirmed as rug | "do not compose / do not sign" |
| `HIGH` | 5+ confirmed rugs / score ≥ 80 | score ≥ 80 | "treat as unsafe; prefer an alternative" |
| `MEDIUM` | 2+ confirmed rugs / score ≥ 50 | score ≥ 50 | "elevated — surface it, proceed with explicit caution" |
| `CLEAN` | no rugs, has tracked tokens | — | "no rug signal" (not "guaranteed safe") |
| `UNKNOWN` | not in database | not yet scanned | "no history found — absence is not safety" |

### `LOW` — why it is not in the table above

The engine can emit `LOW` for a single isolated weak signal. **Do not headline
`LOW` as a verdict.** Its precision is a denominator artifact (a large pool of
barely-flagged tokens, most of which never rug), so quoting it either misleads
or invites a fair rebuttal. Fold `LOW` into "treat as cautious-`UNKNOWN`" and
move on. Cite `CRITICAL` / `HIGH` (and `MEDIUM` when needed) — never `LOW`.

## Precision is per-tier, and it is not perfection

When you report accuracy, report it **per tier** and point at the audit trail —
never as one blended number, and never as "zero false positives" (no detector
is perfect; claiming it invites disproof):

> "CRITICAL precision ~97.x%, HIGH ~95.x% — each verdict auditable per-mint at
> `/v1/predictions/{mint}`."

**Always pull the live figure** from `GET /v1/stats` (`critical_precision_pct`,
`precision_by_tier`) on the day you cite it. Numbers move as outcomes resolve;
a number copied from a doc is already stale.

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
- Score floors: `CRITICAL` ≥ 80, `HIGH` ≥ 60, `MEDIUM` ≥ 40. Low-data tokens
  (<10 holders) carry a soft risk floor so "too new to tell" doesn't read as clean.

## Operator labels (rug rate = confirmed_rugs / total_tokens)

| Label | Threshold | Read as |
|---|---|---|
| `serial_rugger` | ≥ 70% | almost everything they ship rugs |
| `suspicious` | ≥ 40% | more rugs than legit |
| `legit` | < 20% (≥3 tokens) | track record favors legit launches |

Operators with <3 tokens are **unlabelled** — sample too small. Don't infer a
label the API didn't give you.

## Outcome timing (so you qualify "real-time" honestly)

A flagged token is watched before its outcome resolves:

- Fast-track ~6h (risk ≥ 80, or mint+freeze kept, or top holder ≥ 70%)
- Primary resolution ~2 days otherwise
- Volume-dead (<$100 24h volume) resolves immediately

So: the **scan/lookup** is fast (sub-second; the API returns `latency_ms`), but
**outcome confirmation** takes hours to days. Say "sub-50ms scan response" or
"fast on-demand lookup" for the API; say "6h fast-track / ~2-day primary
resolution" for outcomes. Avoid unqualified "real-time."

## Why the rubric is public

The thresholds are published on purpose — a scoring system that hides its rubric
is a black box no serious integrator can adopt. Knowing `CRITICAL = 80` does not
let an attacker game it; the protected work is the *signal detection* (which
patterns map to which increments) and the evolutionary tuning, which stay
private. This is the open-core line: open rubric + open API, private engine.
