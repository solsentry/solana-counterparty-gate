# Reference: audit-handoff (★ where the audit ends, this begins)

Load this when a **bytecode audit just passed** — Trail of Bits, QEDGen,
`safe-solana-builder`, the core `solana-dev` `security.md` checklist, a formal
verification pass — and the user is treating "audit green" as "safe to ship /
safe to integrate."

## The handoff, in one sentence

> The audit told you **your code** is sound. It said nothing about **whose code
> you call**. Before you compose, gate the operator.

A clean audit verifies the bytecode you control. It does not — and structurally
cannot — tell you that the oracle you read, the AMM you route through, or the
lending program you CPI into was deployed by a serial rug operator. Those
program IDs are inputs to your system, not part of the audited surface.

## When to invoke

- After any pre-deploy security skill reports "no critical findings"
- When a checklist item like "third-party program reviewed" is checked off on
  the basis of *reading the other program's code* (necessary, not sufficient)
- Before a mainnet deploy whose instruction set includes CPIs to programs the
  user did not author
- When a DeFi composition (router → AMM → oracle) is being assembled

## Procedure

1. **Enumerate the external counterparties.** Every `program_id` your code
   invokes that you did not write: oracles, AMMs, lending pools, vaults,
   keepers, multisig authorities, fee/treasury destinations.
2. **For each, run the counterparty gate** (`counterparty.md`): resolve to the
   deployer wallet, `check_operator(deployer)`.
3. **For any token mint in the path** (LP token, reward mint), `check_token(mint)`.
4. **Roll up** into a handoff note appended to the audit report.

## Handoff note template

> **Operator-level counterparty gate (SolSentry)** — complements the bytecode
> audit; does not replace it.
>
> | Counterparty | Role | Deployer | Verdict | Note |
> |---|---|---|---|---|
> | `<program_id>` | oracle | `<wallet>` | `CLEAN` | no rug history |
> | `<program_id>` | AMM | `<wallet>` | `HIGH` | `<N>` confirmed rugs — see below |
> | `<program_id>` | vault | `<wallet>` | `UNKNOWN` | not tracked — absence ≠ safe |
>
> Each verdict is auditable per-mint at `/v1/predictions/{mint}`.
> Re-run on the day of deploy — operator profiles update continuously.

## How to frame it to the user (no overclaiming)

- This is an **orthogonal** layer, not a competing audit. Say "the audit covers
  your bytecode; this covers the operators you compose with."
- A `CLEAN`/`UNKNOWN` counterparty does **not** lower the bar on standard CPI
  hygiene (account ownership, signer checks, reload-after-CPI) — keep those.
- Do not present this as "now you're 100% safe." It removes one specific blind
  spot (composing with a known-bad operator), nothing more.

## Why it belongs in the kit

The Solana AI Kit already ships strong **pre-deploy** security (audit, codegen,
formal methods). This reference is the explicit seam between that work and the
one question those tools leave open. It makes the kit's security story complete:
*audit the code, then gate the operator.*
