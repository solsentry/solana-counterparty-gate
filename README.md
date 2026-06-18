# solana-counterparty-gate

A Claude Code skill for **operator-level counterparty risk** on Solana. Before
you CPI into, compose with, or integrate a program / oracle / keeper / multisig
you did not write, check **who operates it** — the question a bytecode audit
cannot answer.

> **Clean code ≠ clean partner.** Run the gate *before* the CPI.

> **Extends**: [solana-dev-skill](https://github.com/solana-foundation/solana-dev-skill) — this skill starts where the audit ends.

## The gap it fills

Every security skill in the Solana AI Kit — Trail of Bits, QEDGen,
`safe-solana-builder`, the core `solana-dev` security checklist — analyzes
**bytecode you control**. None can tell you whether the *third party* you're
composing with has a rug history, because that signal isn't in the bytecode —
it's in the deployer's on-chain track record across other launches.

This skill is the missing axis: **operator-level counterparty risk**, backed by
SolSentry's live mainnet scanner ([`api.solsentry.app`](https://api.solsentry.app),
no API key for reads).

## What's included

| File | Purpose |
|---|---|
| [`skill/SKILL.md`](skill/SKILL.md) | Router: file-pattern triggers, progressive disclosure, risk vocab, MCP tools |
| [`skill/quickstart.md`](skill/quickstart.md) | 60s — MCP via `npx` or plain REST, one real call |
| `skill/counterparty.md` | ★ Pre-CPI/compose check of a third-party deployer/program/oracle |
| `skill/tx-preview.md` | Pre-sign preview + address-poisoning / lookalike check |
| `skill/threat-intel.md` | Generic wallet/mint risk lookup |
| `skill/audit-handoff.md` | ★ Audit passed? Now gate the operator behind the code |
| `skill/forensics.md` | Post-incident fund-flow trace |
| `skill/cluster-graph.md` | Operator / bot-cluster network exploration |
| `skill/br-scams.md` | Brazil-context scam patterns (PT) |
| `skill/interpreting-scores.md` | How to read tiers honestly — `UNKNOWN` ≠ safe |
| [`tests/smoke.sh`](tests/smoke.sh) | Hits live endpoints, asserts schema + `200` |

*(Reference files marked ★ are the novelty axis; remaining `skill/*.md` land in the next build pass.)*

## Install

```bash
git clone https://github.com/solsentry/solana-counterparty-gate
cd solana-counterparty-gate
./install.sh           # or ./install-custom.sh for project / custom paths
```

As a submodule inside another kit project:

```bash
git submodule add https://github.com/solsentry/solana-counterparty-gate .claude/skills/ext/solana-counterparty-gate
```

## Verify

```bash
bash tests/smoke.sh
```

## Honesty contract

Every verdict is **auditable per-mint** at `/v1/predictions/{mint}` — no opaque
score. Precision is reported per tier (CRITICAL / HIGH / MEDIUM), pulled live
from [`/v1/stats`](https://api.solsentry.app/v1/stats). `UNKNOWN` is surfaced as
`UNKNOWN`, never silently coerced to "safe".

SolSentry is **open-core**: the [`@solsentry/mcp`](https://www.npmjs.com/package/@solsentry/mcp)
server, the `solsentry-guard` SDK, and the free read API are open; the scoring
engine is private.

## License

MIT — see [LICENSE](LICENSE). © 2026 SolSentry.

---

> *RugCheck tells you a fire is burning. SolSentry tells you who lit it — before the CPI.*
