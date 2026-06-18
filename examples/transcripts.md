# Example transcripts

Three real interactions against the live API (`api.solsentry.app`), captured
2026-06-18. Scenario 1 names a real on-chain operator; scenarios 2–3 use
placeholder addresses. **Reproduce live** with the curl shown — counts grow as
the scanner resolves more outcomes, so treat any number here as a dated snapshot.

---

## 1. Pre-CPI gate catches a serial rug operator

**User:** "I want to route swaps through this AMM program before I ship. Is its
deployer safe?"

**Agent** resolves the program to its deployer wallet — here, the real serial
operator `4kxscuteRLQdNiTXA33YYsvywAPNA6DQTifswxjL5pH1` — then:

```bash
curl -s https://api.solsentry.app/v1/operator/4kxscuteRLQdNiTXA33YYsvywAPNA6DQTifswxjL5pH1 \
  | jq '{known,risk_level,risk_label,confirmed_rugs,total_tokens,rug_rate_pct,patterns,tags}'
```

```json
{
  "known": true,
  "risk_level": "CRITICAL",
  "risk_label": "mixed",
  "confirmed_rugs": 4611,
  "total_tokens": 4707,
  "rug_rate_pct": 98,
  "patterns": ["fast_deployer", "rebrand_artist"],
  "tags": ["rebrand_artist", "rebuild_2026-05-20", "fast_deployer"]
}
```

**Agent verdict:**

> ⚠️ **CRITICAL.** `4kxscute…5pH1` is a confirmed serial rug operator — live as of
> 2026-06-18: **4,611 confirmed rugs across 4,707 tokens (98% rug rate)**, with
> `fast_deployer` + `rebrand_artist` patterns (it relaunches the same playbook
> under new names). Composing with its program inherits that risk. Every rug is
> auditable per-mint at `/v1/predictions/{mint}`, and the count grows as the
> scanner resolves more outcomes — re-run the curl for the current figure.
>
> Recommend: pick an alternative AMM, or — if unavoidable — require the program be
> immutable (`solana program show <id>` → no upgrade authority) and add a circuit
> breaker. Your own code passing audit does **not** make this counterparty safe.

*This is the gap no bytecode audit fills: the program's code may be fine; the
operator is the risk.*

---

## 2. Address-poisoning lookalike before a transfer

**User:** "About to send to this address I copied — looks like one of my contacts."

```bash
curl -s "https://api.solsentry.app/v1/lookalike-check?destination=<addr>&contacts=<contact_1>,<contact_2>"
```

```json
{
  "destination": "<addr>",
  "suspect": false,
  "confidence": "weak",
  "findings": [
    {
      "original_contact": "<contact_1>",
      "prefix_match": 42,
      "suffix_match": 0,
      "confidence": "weak",
      "reasons": ["collision prefix=42 suffix=0 vs So111111…1113"]
    }
  ],
  "contacts_checked": 2,
  "latency_ms": 0.1
}
```

**Agent verdict:**

> The destination shares a long prefix with one of your contacts but the match is
> `weak` and `suspect:false`, so this looks like a coincidental prefix, not a
> poisoning clone. (If `suspect` came back `true` with `confidence` higher, I would
> stop and tell you exactly which contact it mimics — you'd almost certainly mean
> the contact, not the lookalike.) Run `tx-preview` next before signing.

---

## 3. Clean compose — empty/unknown operator + safe transaction

**User:** "Checking a counterparty wallet and previewing the tx before I sign."

Operator lookup returns no rug history:

```bash
curl -s https://api.solsentry.app/v1/operator/<wallet> | jq '{known,risk_level,confirmed_rugs}'
```

```json
{ "wallet": "<wallet>", "known": false, "risk_level": "UNKNOWN", "confirmed_rugs": 0 }
```

Transaction preview runs the authority-grab detectors:

```bash
curl -s -X POST https://api.solsentry.app/v1/tx-preview \
  -H 'content-type: application/json' -d '{"tx_base64":"<base64-tx>"}'
```

```json
{
  "risk_score": 0,
  "verdict": "safe",
  "findings": [],
  "detectors_run": ["close_account", "owner_reassignment", "stake_authority"],
  "decode_ok": true,
  "latency_ms": 0.2
}
```

**Agent verdict:**

> The transaction preview is `safe` — no account-close, owner-reassignment, or
> stake-authority grab among the detectors run, and it decoded cleanly. Note the
> counterparty is `UNKNOWN`: that means **no rug history was found, not that it's
> proven safe** — a brand-new wallet reads `UNKNOWN` too. Standard CPI hygiene
> (account ownership, signer checks, reload-after-CPI) still applies.

---

> Reproduce any of these: `bash tests/smoke.sh` confirms the endpoints are live,
> then run the curls above with your own addresses.
