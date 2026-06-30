# Reference: calibration (evidence from a live system, not a methodology document)

Other security skills tell you *what to ask* about a deployer ("trace its hops,
check for prior rugs"). This skill **answers** it from a scanner that has been
running on mainnet continuously (1,800h+). This page is the difference made
concrete: worked verdicts on real addresses, each one a single keyless `curl`
you can re-run right now. Every number below is a **dated snapshot** — counts
move as outcomes resolve, so reproduce it live before you quote it.

> Snapshot captured **2026-06-30**. Re-run each `curl` to refresh.

## Case 1 — a confirmed serial rug operator → `CRITICAL`

```bash
curl -s https://api.solsentry.app/v1/operator/4kxscuteRLQdNiTXA33YYsvywAPNA6DQTifswxjL5pH1 \
  | jq '{known,risk_level,risk_score,confirmed_rugs,total_tokens,rug_rate_pct,patterns}'
```
```json
{
  "known": true,
  "risk_level": "CRITICAL",
  "risk_score": 96,
  "confirmed_rugs": 1468,
  "total_tokens": 1608,
  "rug_rate_pct": 91.3,
  "patterns": ["fast_deployer", "rebrand_artist"]
}
```
A real operator the gate flags **before** you compose with anything they shipped.
The signal is the deploy track record across 1,600+ launches — not in the
bytecode of any single one. This is the question no audit skill answers.

## Case 2 — precision is **per-tier and published**, not "zero false positives"

The system's own scorecard is a single keyless call. Note the bottom row:

```bash
curl -s https://api.solsentry.app/v1/stats | jq '.precision_by_tier'
```
```json
{
  "CRITICAL": { "resolved": 43134, "correct": 42159, "precision_pct": 97.7 },
  "HIGH":     { "resolved": 7973,  "correct": 7619,  "precision_pct": 95.6 },
  "MEDIUM":   { "resolved": 21917, "correct": 20821, "precision_pct": 95   },
  "LOW":      { "resolved": 4179,  "correct": 501,   "precision_pct": 12   }
}
```
The `LOW` tier resolves at **12%** — and we publish it. A system that hid its
weak tier could claim a prettier blended number; we don't. This is why the gate
tells you to **act on `CRITICAL`/`HIGH`, never headline `LOW`** (see
`interpreting-scores.md`). Calibration means knowing exactly which verdicts are
load-bearing.

## Case 3 — every verdict is **auditable per-mint** (FPs included)

No opaque score. Each prediction carries its full resolution trail, and the
system surfaces its **own false positives** rather than burying them:

```bash
curl -s https://api.solsentry.app/v1/predictions/<mint> \
  | jq '.predictions[0] | {predicted_risk,outcome_6h,outcome_24h,outcome_3d,outcome_30d,final_outcome,was_correct,resolved_at}'
```
A real trail shows the verdict graduating across horizons
(`outcome_6h` → `outcome_30d`), `was_correct`, and outcomes like `nft_fp` where
an early flag was later **re-classified as a false positive**. That re-class is
visible per-mint on purpose: "auditable" includes auditing where we were wrong.

## Case 4 — no data is `UNKNOWN`, not a verdict (no false GO, no false alarm)

```bash
curl -s https://api.solsentry.app/v1/operator/<wallet-never-seen-deploying> \
  | jq '{known,risk_level,risk_score}'
```
```json
{ "known": false, "risk_level": "UNKNOWN", "risk_score": null }
```
The gate refuses to fabricate a verdict in either direction. An unobserved
wallet returns `UNKNOWN` — explicitly "absence is not safety" — so the skill
never green-lights a partner it has no evidence on, and never red-flags one it
has nothing against. Standard CPI validation applies regardless (see
`counterparty.md`).

## How to report a verdict (the honest contract, applied)

- Lead with the **tier and the live count**, both pulled at call time.
- Point at the audit trail: `auditable per-mint at /v1/predictions/{mint}`.
- Quote **per-tier** precision (CRITICAL ~97.x% / HIGH ~95.x%) from `/v1/stats`
  on the day — never one blended number, never "zero false positives".
- Render `UNKNOWN` as `UNKNOWN`. Never coerce it to "safe".

That is the whole pitch in one line: **a dated, reproducible, per-mint-auditable
verdict from a live system — not a methodology you have to run by hand.**
