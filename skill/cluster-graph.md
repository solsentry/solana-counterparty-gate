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
| 1 | `GET /v1/clusters?limit=20` | Top active bot clusters |
| 2 | `GET /v1/cluster/{cluster_id}` | Members + patterns + associated operators |
| 3 | `GET /v1/operator/{wallet}/timeline` | What tokens this operator has touched, chronologically |
| 4 | `check_operator(wallet)` per member | Risk profile per node |

## Cluster shape

```json
{
  "cluster_id": "c_<id>",
  "size": "<int>",
  "patterns": ["synchronized_buys", "shared_funding_wallet", "common_deploy_window"],
  "associated_operators": ["<wallet>", "<wallet>"],
  "tokens_involved": "<int>",
  "first_observed": "<unix>",
  "last_observed": "<unix>",
  "members": [{ "wallet": "<wallet>", "role": "deployer|buyer|lp_remover|shill" }]
}
```

## Workflow patterns

**From a token:** `check_token(mint)` → deployer → `check_operator(deployer)` →
`/operator/{deployer}/timeline` → overlap buyers across their tokens → match to a
known cluster via `/v1/clusters`.

**From a wallet:** `check_operator(wallet)` → find its `cluster_id` in `/v1/clusters`
→ `/v1/cluster/{id}` for the member graph → recursively `check_operator()` the top members.

**From a cluster:** identify by pattern signature in `/v1/clusters` → pull the
member graph → render as nodes (wallets) + edges (deployer → buyer → lp_remover).

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
