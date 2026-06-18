# Reference: tx-preview & lookalike (pre-sign)

Load this at **pre-sign time**: a transaction is about to be signed, or an
address was pasted from a docs page / Discord / DM and might be a poisoned
lookalike. Two endpoints, two distinct checks.

## 1. Transaction preview — `POST /v1/tx-preview`

Decodes a transaction and runs authority-grab / account-close detectors before
the user signs. Catches the patterns that drain wallets through *signing*, not
through a bad token: ownership reassignment, account closure to an attacker,
stake-authority theft.

**Request** — supply one of:

```bash
curl -s -X POST https://api.solsentry.app/v1/tx-preview \
  -H 'content-type: application/json' \
  -d '{"tx_base64":"<base64-encoded-transaction>"}'
# or a parsed form:
#   -d '{"parsed_tx":{"accounts":[...],"instructions":[...]}}'
```

**Response** (live shape):

```json
{
  "risk_score": 0,
  "verdict": "safe",
  "findings": [],
  "detectors_run": ["close_account", "owner_reassignment", "stake_authority"],
  "decode_ok": true,
  "latency_ms": 0.0
}
```

| Field | Meaning |
|---|---|
| `verdict` | `safe` / elevated — lead with this |
| `risk_score` | numeric score for the transaction |
| `findings` | array of triggered detector findings (empty = none) |
| `detectors_run` | which detectors evaluated this tx (transparency: shows coverage) |
| `decode_ok` | `false` ⇒ the tx could not be decoded — treat as inconclusive, **not** safe |

**Output guidance:** if `findings` is non-empty, name each finding and *do not*
recommend signing. If `decode_ok` is `false`, tell the user the preview was
inconclusive (decode failed) — never imply a failed decode means the tx is fine.

## 2. Lookalike / address-poisoning — `GET /v1/lookalike-check`

Address-poisoning attacks seed your history with a wallet whose first/last
characters mimic an address you actually use, hoping you copy the wrong one.
This check compares a `destination` against your known `contacts`.

```bash
curl -s "https://api.solsentry.app/v1/lookalike-check?destination=<addr>&contacts=<W1>,<W2>,..."
```

**Response** (live shape):

```json
{
  "destination": "<addr>",
  "suspect": false,
  "confidence": "none",
  "findings": [],
  "contacts_checked": 1,
  "latency_ms": 0.0
}
```

| Field | Meaning |
|---|---|
| `suspect` | `true` ⇒ `destination` resembles one of the contacts (likely poisoning) |
| `confidence` | strength of the lookalike match (`none` / higher) |
| `findings` | which contact(s) it mimics and how (prefix/suffix overlap) |
| `contacts_checked` | how many contacts were compared |

**Output guidance:** when `suspect` is `true`, stop and surface *which* real
contact the pasted address is imitating — the user almost certainly meant the
contact, not the lookalike. A vanity prefix/suffix match is **not** proof of a
sibling wallet; it is a copy-paste trap (see the address-poisoning lesson in the
operator-graph references).

## When to use which

| Situation | Endpoint |
|---|---|
| About to sign any transaction | `tx-preview` |
| About to send to a freshly pasted address | `lookalike-check` first, then `tx-preview` |
| Address came from history/clipboard and "looks right" | `lookalike-check` — that's exactly the trap |
