# Reference: cluster-graph (network exploration)

Load this for **research / threat-hunting / journalism** — when the user wants
the *graph* around an address (who else is connected), not just a single verdict.
For a one-address risk check, use `threat-intel.md` instead.

## When to use

- Investigating a scam pattern across multiple tokens
- Mapping a known operator's network of helpers / shills
- Researching an exploit retroactively
- Writing a public post-mortem about a coordinated attack
- "Who else is connected to this wallet?"

## Calls

| Step | Endpoint | Purpose |
|---|---|---|
| 1 | `GET /v1/clusters?limit=20` | A page of bot clusters (`operators`, `sample_wallets`, `associated_rugs` per entry) |
| 2 | `GET /v1/cluster/{cluster_id}` | Members (with `role`) + `tags` + `edges` + `associated_tokens` |
| 3 | `GET /v1/operator/{wallet}/timeline` | What tokens this operator has touched, chronologically |
| 4 | `check_operator(wallet)` per member | Risk profile per node |

## Cluster shape (`GET /v1/cluster/{cluster_id}`)

```json
{
  "cluster_id": "cluster_<id>",
  "size": "<int>",
  "risk_level": "HIGH",
  "risk_score": "<int>",
  "tags": ["high_avg_risk"],
  "first_seen": "<unix>",
  "last_seen": "<unix>",
  "shared_funding_source": null,
  "funding_source_classification": null,
  "members": [{ "wallet": "<wallet>", "role": "operator|buyer", "first_seen": "<unix>", "tokens_deployed": "<int>", "confirmed_rugs": "<int>" }],
  "edges": [],
  "associated_tokens": [{ "mint": "<mint>", "final_outcome": "<outcome>", "predicted_at": "<unix>", "buyers_from_cluster": "<int>" }]
}
```

## Workflow patterns

**From a token:** `check_token(mint)` → `dev_wallet` → `check_operator(dev_wallet)` →
`/v1/operator/{dev_wallet}/timeline` → overlap buyers across their tokens → look for
those wallets in the clusters `/v1/clusters` returns.

**From a wallet:** `check_operator(wallet)` → look for the wallet in the `operators` /
`sample_wallets` of the clusters `/v1/clusters` returns (the list is a page, not a
lookup by wallet) → `/v1/cluster/{cluster_id}` for the member graph → recursively
`check_operator()` the top members.

**From a cluster:** pick one by `tags` / `risk_level` in `/v1/clusters` → pull the
member graph → render as nodes (wallets, by `role`) + `edges` when the API returns them.

## Output guidance

Structure beats prose — researchers want the data:

- **Member table** — wallet · role · risk_level · confirmed_rugs · tags
- **Mermaid graph** — nodes = wallets, edges = observed interactions
- **Timeline** — tokens touched, with rug confirmations marked

## Pitfall (always include this caveat)

Cluster membership is **inferred from on-chain co-activity**, not declared:

> "Cluster membership reflects observed on-chain co-activity. It is evidence of a
> pattern, not proof of off-chain coordination."

A wallet that consistently appears alongside known operators is grouped with
them — correlation, not proof.
