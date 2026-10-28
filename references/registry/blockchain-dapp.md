# Registry pack — blockchain-dapp

> One project-type pack. Load it together with the trigger index in `references/registry.md`,
> never the other packs. Install names, commands and the consent rule: registry.md §Install recipes.

DApp, smart contract, wallet, DEX, or any project involving on-chain code.

```
install:
  off-chain (always):
    - addyosmani/agent-skills
      skills: [incremental-implementation, test-driven-development, security-and-hardening]
  smart-contract tooling (install per chain):
    - EVM: Foundry (forge/cast/anvil) — forge.sh
    - EVM: Slither — pip install slither-analyzer
    - Solana: Anchor — avm install latest
    - TON: Blueprint — npm create ton@latest
    - SUI: SUI CLI — brew install sui

tested-with: Foundry 2025-06, Anchor 0.30+, OpenZeppelin 5.x

CRITICAL:
  Smart contract code requires professional audit before mainnet.
  No AI tool (including Claude Code) replaces Slither + Foundry + human auditor.
  $3.35B lost in 2025: most from security design failures.
  Plan audit timeline: 4-12 week booking queue at major firms.

shipright-adds-to-CLAUDE:
  boundary-keys: "Private keys NEVER in source code, env vars, or logs"
  boundary-oracle: "Never single oracle source for financial data — Chainlink/Pyth"
  boundary-contracts: "All contract calls validate return values — never assume success"
  money-rule: "Token amounts in native units (wei/lamports). No floats for money."
  test-first: "Write failing test BEFORE implementation. Smart contracts have no undo button."
  security-gate: "Run slither + forge test before EVERY testnet deploy. Tests must GREEN first."
  audit-gate: "No mainnet without audit report + all critical/high fixed"
  debt-signals:
    - "TODO[tvl>$10k]: engage professional audit firm"
    - "TODO[tvl>$100k]: formal verification for critical invariants"
    - "TODO[launch]: bug bounty program via Immunefi"

custodial-wallet-specific:
  key-boundary: "Private key decrypted ONLY inside signing action — never passed between layers"
  idempotency: "All dedup checks in DB/Redis — never in-memory Map (lost on restart)"
  state-machine: "Every ticket: explicit states + logged transitions + terminal states immutable"
  scheduler: "Every scheduler: distributed lock + session audit + chunk processing"
  money: "Use Decimal.js/BigNumber for all amounts — never native JS number for money"
  sweep: "Fund sweep: lock account → check pending → sweep → unlock (atomic pattern)"
  nonce: "Concurrent EVM payouts: queue sequentially or use Redis nonce tracker"
  load: references/stacks/blockchain.md — custodial wallet section
```
