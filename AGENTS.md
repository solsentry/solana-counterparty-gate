# solana-counterparty-gate — cross-agent instructions

> **Works in any coding agent.** This file is the agent-agnostic entry point
> (read by Codex, Cursor, and any tool that honors `AGENTS.md`). Claude Code
> users get the richer, progressively-loaded version under [`skill/SKILL.md`](skill/SKILL.md)
> — same capability, different packaging. The underlying data layer (MCP + REST)
> is identical across agents.

## What this skill does

Before you **CPI into / compose with / integrate** a Solana program, oracle,
keeper, AMM, vault, or multisig **you did not write**, check **who operates it**:
is the deployer behind it a known serial rug operator? That signal is not in the
bytecode, so a code audit cannot answer it.

**Clean code ≠ clean partner. Run the gate before the CPI.**

This is the missing axis next to bytecode audits (Trail of Bits, QEDGen,
safe-solana-builder): **operator-level counterparty risk**, backed by SolSentry's
live mainnet scanner.

## When to activate (file-pattern triggers)

Load this guidance when the working file shows a counterparty the user did not author:

- `invoke(` / `invoke_signed(` / `CpiContext::new` — a cross-program invocation
- a hardcoded third-party `program_id` / `declare_id!`
- an imported third-party SDK / oracle / AMM / lending client
- a `Pubkey` literal pasted from docs / Discord / DM (possible address poisoning)
- a multisig / keeper / authority address from an external party

## How to use it (no API key required for reads)

Two interchangeable paths — pick whichever your agent supports.

### A. MCP (portable — Claude Code, Codex, Cursor, …)

Run the server: `npx @solsentry/mcp`. Tools:

| Tool | Purpose |
|---|---|
| `check_operator(wallet)` | Risk profile of a wallet as a token/program **deployer** |
| `check_token(mint)` | Risk profile of a token mint |
| `get_top_operators(limit)` | Leaderboard of worst serial rug operators |
| `get_network_stats()` | System-wide live stats |
| `explain_risk(address)` | Plain-English risk summary for any address |

### B. Plain REST (any agent that can `curl` / `fetch`)

Base URL `https://api.solsentry.app` — keyless for reads.

```bash
# Gate a counterparty's deployer before composing:
curl -s https://api.solsentry.app/v1/operator/<deployer_wallet> \
  | jq '{risk_level, confirmed_rugs, total_tokens, rug_rate_pct, patterns}'

# Token risk:
curl -s https://api.solsentry.app/v1/token/<mint>

# Pre-sign transaction preview (authority-grab + address-poisoning detectors):
curl -s -X POST https://api.solsentry.app/v1/tx-preview \
  -H 'content-type: application/json' -d '{"tx_base64":"<base64-tx>"}'
```

Full per-workflow detail lives in the `skill/` references — load only what's relevant:
`counterparty.md` (★ pre-CPI gate), `tx-preview.md` (pre-sign), `threat-intel.md`
(generic lookup), `audit-handoff.md` (★ after a bytecode audit passes),
`forensics.md` (drain trace), `cluster-graph.md` (operator network),
`br-scams.md` (Brazil context), `interpreting-scores.md` (read tiers honestly).

## Risk vocabulary (act on these)

| Level | Action |
|---|---|
| `CRITICAL` | Confirmed rug / heavy rug-history deployer → **do not compose**; warn loudly |
| `HIGH` | Strong rug signal → treat as unsafe; recommend alternative or defense pattern |
| `MEDIUM` | Elevated signal → surface; proceed with explicit caution |
| `CLEAN` | Tracked, no rug history → standard CPI validation still applies |
| `UNKNOWN` | Never observed deploying → **not proof of safety**; no history ≠ trustworthy |

`LOW` (a single weak signal) is **not load-bearing** — fold into `UNKNOWN`-grade caution.

## Honesty rules (non-negotiable — this is a quality feature)

- Report precision **per tier** (CRITICAL / HIGH / MEDIUM), pulled live from
  `/v1/stats`. Never a blended number. **Never claim "zero false positives"** or
  "100% accurate" — no detector is perfect.
- Every verdict is **auditable per-mint** at `/v1/predictions/{mint}`. Cite it.
- Surface `UNKNOWN` as `UNKNOWN` — never silently coerce it to "safe".
- The scanner is a **fast on-demand lookup**, not a streaming "real-time" feed —
  avoid unqualified "real-time".
- Operator counts are **volatile** (resolve as outcomes settle). Read them live;
  never bake a count into a doc as if it were fixed.

---

*RugCheck tells you a fire is burning. SolSentry tells you who lit it — before the CPI.*
*MIT licensed. © 2026 SolSentry.*
