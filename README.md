# solana-counterparty-gate

A skill for **operator-level counterparty risk** on Solana — for **Claude Code,
Codex, Cursor, and any coding agent**. Before you CPI into, compose with, or
integrate a program / oracle / keeper / multisig you did not write, check **who
operates it** — the question a bytecode audit cannot answer.

> **Clean code ≠ clean partner.** Run the gate *before* the CPI.

> **Any agent:** Claude Code loads [`skill/SKILL.md`](skill/SKILL.md) (progressive,
> token-efficient). Codex / Cursor / others read [`AGENTS.md`](AGENTS.md). The data
> layer — the `@solsentry/mcp` MCP server and the keyless REST API — is identical
> across all of them.

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
| [`skill/counterparty.md`](skill/counterparty.md) | ★ Pre-CPI/compose check of a third-party deployer/program/oracle |
| [`skill/audit-handoff.md`](skill/audit-handoff.md) | ★ Audit passed? Now gate the operator behind the code |
| [`skill/tx-preview.md`](skill/tx-preview.md) | Pre-sign preview + address-poisoning / lookalike check |
| [`skill/threat-intel.md`](skill/threat-intel.md) | Generic wallet/mint risk lookup |
| [`skill/forensics.md`](skill/forensics.md) | Post-incident fund-flow drain trace |
| [`skill/cluster-graph.md`](skill/cluster-graph.md) | Operator / bot-cluster network exploration |
| [`skill/br-scams.md`](skill/br-scams.md) | Brazil-context scam patterns (PT) |
| [`skill/interpreting-scores.md`](skill/interpreting-scores.md) | How to read tiers honestly — `UNKNOWN` ≠ safe |
| [`commands/`](commands/) | `/check-counterparty`, `/check-token` slash commands |
| [`agents/counterparty-analyst.md`](agents/counterparty-analyst.md) | Multi-address screening / written report (sonnet) |
| [`examples/transcripts.md`](examples/transcripts.md) | 3 real interactions captured against the live API |
| [`tests/smoke.sh`](tests/smoke.sh) | Hits live endpoints, asserts schema + `200` |

## Golden demo (60 seconds)

```bash
bash tests/smoke.sh        # endpoints live + schema OK

# Gate a counterparty's deployer before composing. Example: a real, confirmed
# CRITICAL serial rug operator — the count is volatile, so read it live yourself:
curl -s https://api.solsentry.app/v1/operator/4kxscuteRLQdNiTXA33YYsvywAPNA6DQTifswxjL5pH1 \
  | jq '{risk_level, confirmed_rugs, total_tokens, rug_rate_pct, patterns}'
# CRITICAL deployer → don't compose / require immutable program + circuit breaker.

# Preview a transaction before signing (authority-grab detectors):
curl -s -X POST https://api.solsentry.app/v1/tx-preview \
  -H 'content-type: application/json' -d '{"tx_base64":"<base64-tx>"}' \
  | jq '{verdict, findings, detectors_run}'
```

See [`examples/transcripts.md`](examples/transcripts.md) for full worked outputs.

## File-pattern triggers

The skill is designed to load itself when your working file shows a counterparty
you did not author: `invoke(` / `invoke_signed(` / `CpiContext::new`, a hardcoded
third-party `program_id` / `declare_id!`, an imported third-party SDK/oracle/AMM
client, or a `Pubkey` literal pasted from docs/Discord/DM. See `skill/SKILL.md`.

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

### Use with Codex / Cursor / any coding agent

No installer needed — the repo is the skill. Point your agent at
[`AGENTS.md`](AGENTS.md) (Codex and Cursor read it automatically when the repo is
in context), or wire the MCP server, which works in every agent:

```bash
npx @solsentry/mcp        # exposes check_operator / check_token / explain_risk / …
```

Or just `curl` the keyless REST API (`https://api.solsentry.app`) from any agent —
see [`skill/quickstart.md`](skill/quickstart.md).

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
