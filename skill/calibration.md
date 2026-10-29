# Reference: calibration (evidence from a live system, not a methodology document)

Other security skills tell you *what to ask* about a deployer ("trace its hops,
check for prior rugs"). This skill **answers** it from a scanner that has been
running on mainnet continuously (`runtime_hours` in `/v1/stats`). This page is the difference made
concrete: worked verdicts on real addresses, each one a single keyless `curl`
you can re-run right now. Every number below is a **dated snapshot** — counts
move as outcomes resolve, so reproduce it live before you quote it.

> Snapshot captured **2026-06-30**. Re-run each `curl` to refresh.

## Case 1 — a mint flagged `CRITICAL`, then resolved as a confirmed scam

Captured **2026-09-29**.

```bash
curl -s https://api.solsentry.app/v1/token/6n6iS9z5Lz3zMfrGHascQov4ZJu939DRVLUpmAjC55ch \
  | jq '{known,risk_level,risk_score}'
curl -s https://api.solsentry.app/v1/predictions/6n6iS9z5Lz3zMfrGHascQov4ZJu939DRVLUpmAjC55ch \
  | jq '.predictions[] | {predicted_risk,was_correct,final_outcome}'
```
```json
{ "known": true, "risk_level": "CRITICAL", "risk_score": 100 }
{ "predicted_risk": 100, "was_correct": true, "final_outcome": "confirmed_scam" }
```
The call was made before the outcome, and the outcome is recorded per mint, so
anyone can check it. For a deployer wallet, `GET /v1/operator/{wallet}` returns
its deploy track record across launches — a signal that is not in the bytecode
of any single program. This is the question no audit skill answers.

## Case 2 — the track record is a **count you can audit**, not a percentage

The system's scale is a single keyless call, read live:

```bash
curl -s https://api.solsentry.app/v1/stats | jq '{total_predictions, resolved, confirmed_rugs, confirmed_safe}'
```

State it as "over N outcome-tracked predictions, each auditable per mint" (N =
`resolved`). Do not turn it into a precision percentage: most new launches die
anyway, so a ratio quoted without the base rate of the same universe overstates
the signal. The gate tells you to **act on `CRITICAL`/`HIGH`** (see
`interpreting-scores.md`).

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

## Case 4 — no data is `UNKNOWN`, not a verdict

```bash
curl -s https://api.solsentry.app/v1/operator/<wallet-never-seen-deploying> \
  | jq '{known,risk_level,risk_score}'
```
```json
{ "known": false, "risk_level": "UNKNOWN", "risk_score": null }
```
An unobserved wallet returns `UNKNOWN` — "absence is not safety" — so read it
as no evidence either way, not as a green light. Standard CPI validation applies
regardless (see `counterparty.md`).

## How to report a verdict (the honest contract, applied)

- Lead with the **tier and the live count**, both pulled at call time.
- Point at the audit trail: `auditable per-mint at /v1/predictions/{mint}`.
- State the track record as a live count ("over N outcome-tracked predictions") — never a precision or accuracy percentage, never a claim of perfect precision.
- Render `UNKNOWN` as `UNKNOWN`. Never coerce it to "safe".

That is the whole pitch in one line: **a dated, reproducible, per-mint-auditable
verdict from a live system — not a methodology you have to run by hand.**
