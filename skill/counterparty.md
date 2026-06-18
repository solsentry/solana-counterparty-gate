# Reference: counterparty (★ the core gate)

**Pre-CPI / pre-compose counterparty risk check.** Load this when the user is
about to integrate with, CPI into, or compose with a Solana program, oracle,
AMM, lending pool, vault, keeper, or multisig **they did not write themselves**.

## When to use

- "I want to CPI into program X"
- Integrating an oracle, AMM, lending pool, vault, staking program
- Choosing between two SDKs / programs to integrate
- Reviewing a contract that delegates to other programs via CPI
- Code generation produced a `program_id` / `declare_id!` the user did not author
- An external party handed over a keeper, authority, or multisig address

## Why this is a distinct question

Bytecode audits (`safe-solana-builder`, Trail of Bits, QEDGen, the core
`solana-dev` `security.md`) verify **the user's own code**. They cannot verify
the **operator** behind a program the user merely *calls into*. A CPI to a
program shipped by a serial rug operator inherits that operator's risk: the
user's code can be perfect and the integration still unsafe because the
counterparty is a honeypot.

**Clean code ≠ clean partner.** This is the gap SolSentry fills.

## Procedure

| Step | What | Tool / call |
|---|---|---|
| 1 | Resolve the program to its **deployer wallet** | Solana RPC (below) |
| 2 | Score the deployer | `check_operator(deployer)` → `GET /v1/operator/{wallet}` |
| 3 | If `CRITICAL`/`HIGH` → warn + suggest a defense or alternative | output guidance below |
| 4 | If the integration is a *token* (e.g. an LP mint), also score the mint | `check_token(mint)` → `GET /v1/token/{mint}` |

### Step 1 — resolve program → deployer

The operator database is keyed on **wallets**, not program IDs. Resolve the
program's upgrade authority first:

```bash
# Simplest — the Solana CLI prints the upgrade authority directly:
solana program show <program_id>        # → "Authority: <wallet>"   (that wallet is the operator)
```

```ts
// Programmatically with @solana/kit (2026 stack; client setup lives in the core solana-dev skill):
import { createSolanaRpc, address } from "@solana/kit";
const rpc = createSolanaRpc(rpcUrl);
// An upgradeable program account points at its ProgramData account, which holds the authority:
const program = await rpc.getAccountInfo(address(programId), { encoding: "jsonParsed" }).send();
const programDataAddr = program.value?.data?.parsed?.info?.programData;
const programData = await rpc.getAccountInfo(address(programDataAddr), { encoding: "jsonParsed" }).send();
const deployer = programData.value?.data?.parsed?.info?.authority;   // ← score this wallet
```

If SolSentry already indexed the deployer, you can skip RPC and query directly:

```bash
curl -s https://api.solsentry.app/v1/operator/<deployer_wallet> \
  | jq '{risk_level, confirmed_rugs, total_tokens, rug_rate_pct, patterns, tags}'
```

> **Pitfall:** do not pass the *program ID* to `check_operator` — operators are
> wallets. Always resolve to the deployer/upgrade-authority wallet first. (The
> one exception: a launchpad program-as-mint that `check_token` handles directly.)

## Output guidance

**Deployer is `CRITICAL` / `HIGH`:**

> ⚠️ Program `<program_id>` was deployed by `<deployer>`, an operator scored
> **`<RISK_LEVEL>`** — `<N>` confirmed rugs across `<M>` tokens
> (`<rate>%` rug rate). Composing with a program from this operator inherits
> that risk. Verdict auditable per-mint at `/v1/predictions/{mint}`.
>
> Options:
> - Prefer an alternative provider for this capability.
> - If you must integrate, require the program be **immutable**
>   (`solana program show <id>` → no upgrade authority) so the operator cannot
>   swap the logic post-integration.
> - Add a circuit breaker that halts your program on anomalous counterparty behavior.
> - Constrain the CPI: minimal accounts, no delegated authority, reload-after-CPI.

**Deployer is `CLEAN`:**

> ✓ Program `<program_id>` was deployed by an operator with no confirmed rug
> history (risk score `<score>/100`). No operator-level red flag. Standard CPI
> validation still applies: account ownership, signer checks, reload after CPI.

**Deployer is `UNKNOWN`:**

> ⓘ The deployer of `<program_id>` (`<wallet>`) is **not in SolSentry's tracked
> operator database** — no observed deploy history. This is neither green nor
> red: absence is silence, not a clean record. Standard CPI validation is
> required regardless, and re-check before mainnet.

Never render `UNKNOWN` as "safe." See `interpreting-scores.md`.

## Numbers

Any count you cite (`confirmed_rugs`, `rug_rate_pct`) comes straight from the
live response — never bake a number into prose; it changes as the scanner
resolves outcomes. Pull it at call time and show it with its `/v1/predictions/{mint}`
auditability.
