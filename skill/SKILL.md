---
name: solana-counterparty-gate
description: Counterparty & intent gate for Solana — before you CPI into, compose with, or integrate a program/oracle/keeper/multisig you did not write, check who operates it. Answers "is the deployer behind this counterparty a known serial rug operator?" — the question bytecode audits cannot. Backed by SolSentry's live mainnet scanner (api.solsentry.app). Clean code ≠ clean partner.
user-invocable: true
license: MIT
compatibility:
  - Claude Code
  - Codex
  - Cursor
  - any agent honoring AGENTS.md
metadata:
  author: solsentry
  version: 1.0.0
  homepage: https://github.com/solsentry/solana-counterparty-gate
  api_base: https://api.solsentry.app
  auth: none (keyless for reads)
  mcp_server: "@solsentry/mcp"
tags:
  - security
  - counterparty
  - operator-risk
  - rug
  - cpi
  - pre-sign
  - solana
---

> **Any agent:** the cross-agent entry point is [`AGENTS.md`](../AGENTS.md) (read by
> Codex, Cursor, and any tool honoring `AGENTS.md`). The data layer (MCP + keyless
> REST) is identical across agents; this file is the Claude Code-native, progressively
> loaded version.

# Solana Counterparty Gate

> **Extends**: [solana-dev-skill](../solana-dev/SKILL.md) — core Solana development (programs, frontend, testing, security audit).

Bytecode audits answer *"is this code safe?"*. This skill answers a different,
orthogonal question: *"is the **operator** behind the program I'm about to
compose with safe?"* A flawless CPI into a program shipped by a serial rug
operator still inherits that operator's risk profile.

**Clean code ≠ clean partner.** Run the gate *before* the CPI.

SolSentry tracks the **operators** behind Solana token launches and program
deployments — serial rug operators, coordinated bot clusters, malicious
deployers — from a scanner running continuously on mainnet. This skill exposes
that intelligence to AI agents at compose / integration / pre-sign time. All
reads hit the public REST API at `api.solsentry.app` — no API key required.

## The gap this fills (why it's not another audit skill)

Every security skill in the kit — Trail of Bits, QEDGen, `safe-solana-builder`,
the core `solana-dev` security checklist — analyzes **bytecode you control**.
None of them can tell you whether the *third party* you're integrating with has
a rug history, because that signal is not in the bytecode — it's in the
deployer's on-chain track record across other tokens.

This skill is the missing axis: **operator-level counterparty risk**. It is
designed to run *after* a code audit passes — see `audit-handoff.md`.

### Methodology vs. live data (why this isn't a checklist)

Skills that name "deployer reputation" operationalize it as **manual
methodology**: trace 1–3 hops by hand, per query, with no index behind it. They
tell you *what to ask*. This skill **answers** it — backed by a scanner running
continuously on mainnet that has already resolved the history, so a lookup
returns a dated, per-mint-auditable verdict in milliseconds (the API returns
`latency_ms`). A worked, reproducible side-by-side lives in `calibration.md`.
**The differentiator is not a better checklist — it's a live system instead of one.**

## File-pattern triggers (load this skill when the working file contains)

When editing Solana code, load this skill if you see a counterparty you did not author:

| Pattern | Why it triggers |
|---|---|
| `invoke(` / `invoke_signed(` / `CpiContext::new` | A cross-program invocation — check the target program's deployer |
| A hardcoded `program_id` / `declare_id!` you did not write | Composing with a third-party program |
| An imported third-party SDK / oracle / AMM / lending client | Integrating an external operator's surface |
| A `Pubkey` literal pasted from a docs page, Discord, or DM | Possible address-poisoning / lookalike — see `tx-preview.md` |
| A multisig / keeper / authority address from an external party | The authority behind it has an operator history |

## When to load each reference (progressive disclosure — load only what's relevant)

| Reference | Load when |
|---|---|
| `counterparty.md` | ★ User is about to CPI into / compose with / integrate a program, oracle, AMM, lending pool, vault, or deployer they did not write |
| `tx-preview.md` | Pre-sign: a transaction is about to be signed, or a pasted address may be a lookalike (address poisoning) |
| `threat-intel.md` | Generic risk lookup on any wallet or mint, no specific workflow |
| `audit-handoff.md` | ★ A bytecode audit (ToB / QEDGen / core `security.md`) just passed — now gate the operator behind it |
| `forensics.md` | Post-incident: a drain / exploit / suspicious flow needs a fund-flow trace |
| `cluster-graph.md` | Researching the operator/bot network around a wallet, mint, or scam pattern |
| `br-scams.md` | Brazil-context scam patterns (KOL/Telegram pumps, vanity-address poisoning) |
| `interpreting-scores.md` | How to read tiers honestly — what each level means, what `UNKNOWN` does *not* mean, how not to over-interpret |
| `calibration.md` | ★ Worked, dated, reproducible verdicts on real addresses — the live-data-vs-methodology proof, per-tier precision, FP transparency |
| `operator-history.md` | The cross-launch deploy timeline behind a verdict (`/v1/operator/{wallet}/timeline`) — cadence, span, per-launch outcomes |

## Tools (MCP — from `@solsentry/mcp`)

These are exposed by the `@solsentry/mcp` server (`npx @solsentry/mcp`).
References describe when and how to invoke them. The same data is available over
plain REST (see `quickstart.md`) for agents without MCP.

| Tool | Purpose |
|---|---|
| `check_operator(wallet_address)` | Risk profile of a wallet as a token/program deployer |
| `check_token(mint_address)` | Risk profile of a token mint |
| `get_operator_timeline(wallet)` | Cross-launch deploy history behind a verdict — see `operator-history.md` |
| `get_network_stats()` | System-wide live stats (`/v1/stats`) |
| `explain_risk(address)` | Plain-English risk summary for any address |

> The worst-operator **leaderboard** (`get_top_operators` / `/v1/top-operators`)
> is intentionally **not public** — enumerating the top serial operator is gated
> by design. Look operators up **by address**; that is the supported path.

## Risk vocabulary (used across all references)

Actionable tiers — these are the levels you act on:

| Level | Meaning | Action |
|---|---|---|
| `CRITICAL` | Confirmed rug, or deployer with a heavy confirmed-rug history | Do not compose. Warn loudly. |
| `HIGH` | Strong rug signal / high risk score | Treat as unsafe; recommend an alternative or a defense pattern |
| `MEDIUM` | Elevated signal worth surfacing | Surface to the user; proceed with explicit caution |
| `CLEAN` | Tracked, no rug history | No rug signal — standard CPI validation still applies |
| `UNKNOWN` | Not in the database (never observed deploying) | **Not proof of safety** — no history ≠ trustworthy |

> The API may also return `LOW` for a single weak/isolated signal. Treat `LOW`
> as **not load-bearing** — do not headline it as a verdict; fold it into
> `UNKNOWN`-grade caution. See `interpreting-scores.md`.

`UNKNOWN` means no on-chain history as a deployer was found — it is neither a
green nor a red flag. Standard CPI validation (account ownership, signer checks,
reload-after-CPI) is required regardless of tier.

## Honesty contract (this is a quality feature, not a disclaimer)

- Every operator/token verdict is **auditable per-mint** at
  `/v1/predictions/{mint}` — the skill never asks you to trust an opaque score.
- Precision is reported **per tier** (CRITICAL vs HIGH vs MEDIUM), not as one
  blended number, and never as "zero false positives".
- `UNKNOWN` is surfaced as `UNKNOWN`, not silently coerced to "safe".
- Live numbers come from `/v1/stats` — `quickstart.md` shows how to pull them
  fresh rather than trusting a number baked into a doc.

## Data freshness & latency

The scanner runs continuously on mainnet (1,800h+ of cumulative runtime).
Operator profiles update within ~30 seconds of new on-chain activity. The API
returns a per-request `latency_ms`; lookups are typically sub-second, suitable
for an in-loop pre-CPI / pre-sign check as well as for offline research. (This
is a fast on-demand lookup, not a streaming "real-time" feed.)

## Supply-chain safety (what this skill is allowed to do)

A security skill must itself be safe to install. This one is, by construction:

- **Read-only** — every operation is a `GET` (or read-only `POST` for tx-preview).
  It never writes, signs, or sends a transaction.
- **Keyless boot** — read endpoints need no API key, no signup, no secret. Nothing
  to leak, nothing to phish. (`auth: none` in the frontmatter.)
- **Zero writes to your machine / chain** — no files created outside the install
  path, no on-chain state mutated, no wallet access requested.
- **No telemetry** — the skill phones home to exactly one place, the public
  `api.solsentry.app` read API, and only for the lookup you asked for. No
  analytics, no beacons, no background calls.
- **MIT, minimal deps** — the skill is Markdown + curl; the optional MCP server is
  a single published package (`@solsentry/mcp`). No transitive install surface
  baked into the skill itself.
- **Stateless** — read queries hit a stateless REST API; no user data is stored.

## Scope guarantees

This skill never:

- Requires authentication for read endpoints
- Advises on pre-deploy work (codegen, audits, formal proofs) — that is the core
  `solana-dev` skill's job. This skill starts where the audit ends.

## Positioning

SolSentry is **open-core**: the `@solsentry/mcp` server, the `solsentry-guard`
client SDK, and the free read API are open; the scoring engine is private. The
intelligence is operator-graph + evolutionary (ALife) agents, not a black-box
"AI" label. (Describe it this way; don't call it "AI-powered" or "open-source".)

## Commands

| Command | Description |
|---|---|
| `/check-counterparty <program\|wallet>` | Resolve to deployer, return a formatted operator verdict |
| `/check-token <mint>` | Token mint risk verdict |

## Agents

| Agent | Purpose |
|---|---|
| `counterparty-analyst` (sonnet) | Multi-address screening / written counterparty report |

## Links

- Homepage: https://solsentry.app
- API: https://api.solsentry.app
- NPM: https://www.npmjs.com/package/@solsentry/mcp
- GitHub: https://github.com/solsentry
