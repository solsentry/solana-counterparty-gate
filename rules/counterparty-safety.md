---
globs:
  - "**/*.rs"
  - "**/*.ts"
  - "**/*.tsx"
exclude:
  - "**/target/**"
  - "**/node_modules/**"
---

# Counterparty Safety Rules

Apply these whenever code composes with, invokes, or integrates a Solana program,
oracle, AMM, vault, keeper, or multisig the project did not author. They encode
the operator-level checks a bytecode audit does not cover.

## Before a CPI / compose, gate the operator

### When you see a cross-program invocation into a third party

```rust
// ❌ Composing without checking who deployed the target program
invoke(&ix, &accounts)?;            // target program_id is third-party

// ✅ Gate the deployer first (check_operator / GET /v1/operator/<deployer>).
//    CRITICAL or HIGH → do not compose, or require a defense pattern below.
```

- Resolve the target `program_id` to its **deployer wallet**, then check that
  wallet's operator risk. The risk is in the deployer's track record across other
  launches, not in this program's bytecode.
- `CRITICAL` / `HIGH` deployer → **do not compose**. If unavoidable: require the
  program be immutable (`solana program show <id>` → no upgrade authority) and add
  a circuit breaker.

## Treat UNKNOWN as not-safe-by-default

```rust
// ❌ Absence of a rug history read as "safe to trust"
// "check_operator returned UNKNOWN, so we're good" — WRONG.

// ✅ UNKNOWN = never observed deploying. Neither green nor red. Apply standard
//    CPI validation (account ownership, signer checks, reload-after-CPI) anyway.
```

## Never overstate the signal (honesty)

- Report risk **per tier** (CRITICAL / HIGH / MEDIUM), pulled live. **Never**
  "zero false positives" or "100% accurate".
- `LOW` is a single weak signal — **not load-bearing**. Do not headline it.
- Operator counts are **volatile**; read them live, never hardcode a count.
- Cite the per-mint audit trail (`/v1/predictions/{mint}`), never an opaque score.

## Pre-sign: validate pasted addresses

```ts
// ❌ Signing with an address pasted from docs / Discord / DM, unchecked
const recipient = new PublicKey("Vanity...lookalike");

// ✅ Run tx-preview (POST /v1/tx-preview) — authority-grab + address-poisoning
//    detectors — before constructing or signing.
```

Standard CPI validation (account ownership, signer checks, reload-after-CPI)
applies regardless of any operator verdict. The operator gate is **additive** to,
not a replacement for, code-level safety.
