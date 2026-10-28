# Stack Reference: Blockchain Projects

## Critical distinction upfront

Blockchain projects have TWO distinct layers — shipright covers one, not both:

```
Layer 1: Off-chain application (backend API, frontend DApp, wallet UI)
  → Shipright covers this fully: constitution, boundaries, quality gate, registry

Layer 2: Smart contracts (on-chain code)
  → Shipright provides workflow structure ONLY
  → Security requires: specialized tools + human audit before mainnet
  → No AI tool, including Claude Code, replaces a formal security audit
  → $3.35 billion lost in 2025: most from design/security failures, not implementation bugs
```

---

## Project type → register entry mapping

| Project | Smart contract? | Off-chain? | Load |
|---|---|---|---|
| Wallet (non-custodial) | No SC logic | Yes | web-api + this file |
| DApp frontend | Interface only | Yes | full-stack-web + this file |
| EVM smart contract | YES | No off-chain | This file security section |
| DApp + smart contract | YES | YES | All sections |
| DEX / AMM | YES — critical | YES | This file + MANDATORY audit |
| Exchange (CEX) | Optional | YES | web-api + this file |

---

## Blockchain-specific boundaries (beyond the core 5 — add to CLAUDE.md)
> These are domain-specific boundaries for blockchain, in ADDITION to shipright's core boundaries 1–5
> (Boundary 5 = integration timeout + fallback, see SKILL.md). Not a renumbering of the core set.

```markdown
## Blockchain boundary rules

### Smart contract boundary
Smart contract code (Solidity/Rust/Move) is a separate trust domain.
Never pass sensitive business logic through off-chain systems if it must be trustless.
Off-chain API calls to contract: always validate return values — never trust blindly.

### Wallet/key boundary  
Private keys NEVER touch application code.
Private keys NEVER appear in logs, env vars committed to git, or error messages.
Key management: hardware wallet > MPC > encrypted keystore. Never plaintext.

### Oracle boundary
External price data / off-chain data entering smart contracts = oracle problem.
Never use a single oracle source for financial calculations.
Chainlink / Pyth for production. Never build your own oracle for financial data.

### Upgrade boundary
Upgradeable contracts (proxy patterns) = administrative risk surface.
Upgrade function must have: timelock + multisig + event emission.
Document upgrade path in ARCHITECTURE.md before writing first line of proxy code.
```

---

## Chain-specific architecture decisions (ask at L0)

### EVM (Ethereum, Polygon, Arbitrum, Base, BSC, TRON)
```
Language: Solidity (primary), Vyper (security-focused alternative)
Testing: Foundry (fast, Solidity-native) > Hardhat (JS ecosystem)
Security scanner: Slither (free, comprehensive) + Aderyn (Rust-based, 2024)
Formal verification: Certora Prover (if TVL > $1M justified)
Libraries: OpenZeppelin (battle-tested, $50B secured) — never reinvent

Key decisions at L0:
□ Upgradeable or immutable? (proxy adds complexity + risk)
□ Which ERC standards? (ERC-20, ERC-721, ERC-4626...)
□ Access control model? (Ownable, AccessControl, multisig)
□ Emergency pause? (Pausable pattern from OpenZeppelin)
```

### Solana (Rust + Anchor framework)
```
Language: Rust with Anchor framework
Testing: Anchor's test framework, Bankrun for fast local testing
Security scanner: cargo audit (dependencies), Anchor constraints (#[account])
Key difference from EVM: account model, not contract-centric model

Key decisions at L0:
□ Anchor or native Rust? (Anchor for most cases — safety constraints built-in)
□ Account ownership model — every account has explicit owner
□ CPI (Cross-Program Invocation) trust model
□ Verifiable builds: anchor build --verifiable (proves source matches on-chain)
```

### TON (FunC / Tact)
```
Language: Tact (recommended, Rust-like) or FunC (low-level)
Testing: Blueprint framework
Key difference: actor model, async message passing between contracts
Cell-based data structure is unique to TON

Key decisions at L0:
□ Message flow design (TON is async — design for partial failures)
□ Tact vs FunC (Tact for new projects, FunC for performance-critical)
```

### SUI (Move)
```
Language: Move (Rust-like, object-centric)
Testing: SUI Move Test framework
Key difference: object model, not account model. Objects have owners.
Move's type system prevents many common vulnerabilities at compile time.

Key decisions at L0:
□ Object ownership model (owned, shared, frozen)
□ Capability pattern for access control
□ Module upgrade policy (immutable vs upgradeable)
```

---

## Walking skeleton for blockchain project

### DApp with smart contract
```
Phase 1 (local testnet): Test-first from day one
  1. Write failing test FIRST:
     EVM:    forge test → RED (contract not written yet)
     Solana: anchor test → RED
  2. Implement contract until test GREEN
  3. Deploy to local chain (Anvil/Hardhat node/Bankrun)
  4. Build off-chain adapter calling deployed contract
  5. Gate: forge test (or anchor test) PASSES on local chain

  NEVER deploy to public testnet with failing tests.
  NEVER write contract code before test. Smart contracts have no undo button.

  Minimum test coverage for any function handling funds:
    □ happy path (correct input, expected output)
    □ failure case (wrong caller, insufficient balance)
    □ edge case (zero amount, max uint256)
    □ revert case (invalid state, unauthorized)

  EVM example:
    function test_deposit_emits_event() public {
      vm.expectEmit(true, true, false, true);
      emit Deposited(user, 100e18);
      vault.deposit{value: 100e18}();
    }
    function test_deposit_reverts_when_paused() public {
      vault.pause();
      vm.expectRevert("Pausable: paused");
      vault.deposit{value: 1 ether}();
    }

Phase 2 (testnet): Real contract
  1. Write contract with tests (100% line coverage minimum)
  2. Run Slither/Aderyn — fix ALL high/medium issues
  3. Deploy to public testnet (Sepolia, Devnet, Testnet)
  4. Test with real testnet funds
  Gate: no issues after 1 week testnet operation

Phase 3 (mainnet): AUDIT FIRST
  1. Professional audit (see security section below)
  2. Fix ALL critical/high issues
  3. Second audit or verification of fixes
  4. Bug bounty program before significant TVL
  Gate: audit report + fixed issues + community testnet period
```

### Non-custodial wallet
```
Phase 1: Key generation + signing (no network)
  1. BIP-39 mnemonic generation (never self-implement — use battle-tested lib)
  2. HD wallet derivation (BIP-44 paths)
  3. Transaction signing (offline, no network calls)
  Gate: sign transaction locally, verify signature correct

Phase 2: Network integration
  1. RPC connection (Infura/Alchemy/QuickNode — never run your own for MVP)
  2. Balance fetch, transaction broadcast
  3. Fee estimation
  Gate: send real testnet transaction, verify on explorer

Phase 3: Security hardening
  1. Encrypted keystore (AES-256, PBKDF2)
  2. No private key in logs, memory dumps, crash reports
  3. Clear memory after key use
  Gate: security audit of key handling paths
```

---

## Security — non-negotiable before mainnet


This section contains the minimum security work before any contract touches real funds.
No AI tool replaces human audit. No Claude Code session replaces Slither + Foundry + auditor.


### Top vulnerabilities (OWASP Smart Contract Top 10, 2025)

```
1. Reentrancy — external call before state update
   Fix: checks-effects-interactions pattern, ReentrancyGuard
   Check: Slither detects most cases

2. Access Control — missing permission checks
   $1.6B lost to this in 2025 alone
   Fix: explicit access control on every state-changing function
   Check: manual review — Slither misses complex logic

3. Integer overflow/underflow — arithmetic errors
   Fix: Solidity 0.8+ has built-in protection. Use it.
   Old contracts: SafeMath library

4. Oracle manipulation — price feed attacks
   Fix: Chainlink/Pyth with TWAP, circuit breakers, multiple sources
   Check: manual review of all price-sensitive calculations

5. Flash loan attacks — unchecked within-block state
   Fix: snapshot balances at start, validate at end
   Check: manual review + property-based testing (Echidna)

6. Front-running — MEV exploitation
   Fix: commit-reveal schemes, slippage protection, deadline params
   Check: manual analysis of transaction ordering dependencies

7. Upgradeable proxy issues — storage collision, initialization
   Fix: OpenZeppelin transparent/UUPS proxy only, initializer guards
   Check: manual review of proxy pattern implementation
```

### Defense patterns (code) — the ones Claude must get exactly right

> Don't roll your own — use OpenZeppelin's audited implementations (ReentrancyGuard, AccessControl,
> ECDSA, upgradeable proxies). Masters: Trail of Bits (building-secure-contracts), OpenZeppelin,
> ConsenSys best practices, the SWC registry.

```solidity
// 1. Reentrancy → Checks-Effects-Interactions + ReentrancyGuard
function withdraw(uint amount) external nonReentrant {          // guard (OZ ReentrancyGuard)
    require(balances[msg.sender] >= amount, "insufficient");    // CHECKS
    balances[msg.sender] -= amount;                             // EFFECTS (state BEFORE the call)
    (bool ok,) = msg.sender.call{value: amount}("");            // INTERACTIONS (external call last)
    require(ok, "transfer failed");
}
// ✗ the classic bug: external call BEFORE updating balances → attacker re-enters and drains.

// 2. Access control → explicit, on every state-changing function (OZ AccessControl/Ownable)
function setFee(uint fee) external onlyRole(ADMIN_ROLE) { ... } // never leave it unguarded ($1.6B lost 2025)

// 3. Auth → msg.sender, NEVER tx.origin
require(msg.sender == owner, "not owner");                      // tx.origin is phishable — never use for auth

// 4. Signature replay → EIP-712 typed data + a per-signer nonce
bytes32 digest = _hashTypedDataV4(keccak256(abi.encode(TYPEHASH, to, amount, nonces[signer]++)));
require(ECDSA.recover(digest, sig) == signer, "bad sig");       // nonce++ makes each sig single-use
// Include chainId + contract address in the domain separator → no cross-chain / cross-contract replay.

// 5. Upgradeable proxy → initializer (not constructor), no storage-layout changes, OZ UUPS/Transparent
function initialize(...) external initializer { ... }           // constructors don't run behind a proxy
```

Oracle/flash-loan (from the list above): use Chainlink/Pyth + TWAP, validate within-block invariants,
never price off a single spot AMM reserve. Front-running: slippage + deadline params, commit-reveal.

### Invariant & property-based testing (beyond unit tests — Trail of Bits standard)

Unit tests check examples; invariant tests check properties across thousands of fuzzed sequences —
this is how you catch the exploit you didn't think of. Required for anything holding real funds.

```solidity
// Foundry invariant test — a property that must hold no matter what sequence of calls runs
contract VaultInvariants is StdInvariant, Test {
    function setUp() public { targetContract(address(vault)); }
    // The vault can never owe more than it holds:
    function invariant_solvency() public { assertGe(address(vault).balance, vault.totalDeposits()); }
    // Accounting integrity: sum of balances == recorded total:
    function invariant_accounting() public { assertEq(vault.sumBalances(), vault.totalDeposits()); }
}
```
```bash
forge test                       # unit + invariant tests
forge test --fuzz-runs 10000     # deeper fuzzing on parameterized tests
echidna VaultInvariants.sol      # Echidna — property fuzzer (Trail of Bits), finds edge sequences
```
Fork-test against mainnet state (`forge test --fork-url $RPC`) for integrations (oracles, DEXes, tokens).

### Mandatory security tools (run before EVERY testnet deploy)

```bash
# EVM/Solidity
slither . --json slither-report.json       # static analysis, 40+ detectors
aderyn .                                    # Rust-based, catches different issues
forge test --gas-report                     # tests + gas profile
forge coverage                              # must be > 90% line coverage

# Solana/Rust
cargo audit                                 # dependency vulnerabilities
cargo clippy                                # linting
anchor test                                 # integration tests

# Both
Review output manually — tools find 60-70% of issues, humans find the rest
```

### Audit strategy by project size

```
Proof of concept (testnet only, no real funds):
  → Automated tools (Slither + Foundry tests) + self-review
  → Bug bounty via Immunefi when ready to grow

Small project (TVL < $100k):
  → Automated tools + community audit (Code4rena contest, $5-30k)
  → At minimum: 2 independent reviewers

Medium project (TVL $100k–$10M):
  → Professional audit firm: Hacken, Cyfrin, SpearBit, Sherlock
  → 4-12 week booking queue — plan ahead
  → Cost: $15k–$100k depending on scope

Large project / DeFi (TVL > $10M):
  → Tier-1 firm: Trail of Bits, OpenZeppelin, Zellic
  → Formal verification: Certora Prover for critical invariants
  → Multiple independent audits
  → Ongoing bug bounty (Immunefi) with significant rewards
  → Never launch with unresolved high/critical findings
```

---

## CLAUDE.md additions for blockchain project

```markdown
## Blockchain rules

### Key management (non-negotiable)
Private keys NEVER in: source code, environment variables committed to git, logs, error messages.
Key material clears from memory after use.
Wallet connection: read-only first, request signing only when needed.

### Smart contract interaction
All contract calls: validate return values — never assume success.
Transaction submission: always include deadline + slippage params for DeFi.
Failed transactions: log error code, do NOT expose revert reason to end user in prod.

### Money amounts
All token amounts in contract-native units (wei for ETH, lamports for SOL).
Never use floating point for financial calculations.
Human-readable display: format at UI layer only, never store formatted strings.

### Security tools (run before every testnet deploy)
EVM: slither . && forge test --gas-report
Solana: cargo audit && anchor test
Never deploy to testnet without green tools output.

### Audit gate
No mainnet deploy without:
□ Professional audit report
□ All critical/high issues resolved
□ Audit firm confirms fixes
```

---

## Off-chain component (shipright handles fully)

The backend API, indexer, frontend — these follow standard shipright workflow:

```
Backend API (reads blockchain data, serves frontend):
  → web-api registry pack (references/registry/web-api.md)
  → Standard boundaries apply
  → RPC calls to blockchain = third-party API (Boundary Rule 4 applies)
  → Use references/third-party-apis.md: Adapter pattern for RPC responses

Frontend DApp:
  → full-stack-web registry pack (references/registry/full-stack-web.md)
  → taste-skill for UI (if applicable)
  → Wallet connection = third-party API (WalletConnect, MetaMask SDK)
  → NEVER trust frontend validation for financial operations

Indexer / event processor:
  → Background worker pattern
  → Idempotent processing (blockchain events can be re-delivered)
  → Checkpoint recovery (last processed block number persisted)
```

---

## Tested-with ecosystem tools

```
EVM:
  Foundry: current (forge, cast, anvil, chisel)
  Hardhat: 2.22+
  OpenZeppelin Contracts: 5.x
  Slither: current
  Ethers.js: 6.x | Viem: 2.x (recommended for new projects)

Solana:
  Anchor: 0.30+
  Solana Web3.js: 1.x | @solana/kit (new)
  cargo-audit: current

TON:
  Blueprint: current
  Tact: 1.x

SUI:
  SUI Move: current
  @mysten/sui: 1.x

Wallets / connection:
  WalletConnect: v2+ (AppKit)
  MetaMask SDK: current
  Phantom: current (Solana)
```

---

## Custodial wallet system — learned from real production

> This section addresses patterns specific to systems where YOU hold private keys.
> Source: analysis of real multi-chain custodial payment hub (EVM/SOL/TRON/TON/SUI).

### The private-key boundary (custodial-specific)

```
Private-key boundary — key only decrypted INSIDE the signing action
  Private key lifecycle: generate → encrypt → store(DB) → decrypt(signing action only) → sign → CLEAR
  Private key NEVER:
    - Passed as function argument between layers
    - Returned from any function
    - Stored in class property
    - Logged in any form
    - Exposed in API response (delete before returning)

  Correct pattern:
    account = await accountRepository.get(id)
    account.privateKey = crypt.decryptToString(account.privateKey)  // decrypt here
    tx = await provider.sign(ticket, account)                        // sign immediately
    account.privateKey = ''                                          // clear immediately
    // account never leaves this scope with decrypted key
```

### Idempotency is structural — never in-memory

```
Wrong (real bug found in production code):
  const lastSentLogs = new Map<string, Date>()  // module-level — lost on restart
  const isTaskRunning = false                    // module-level — useless with 2 servers

Right — idempotency key in DB or Redis:
  // Before processing:
  const existing = await db.idempotencyKey.findUnique({ where: { key: ticket.id } })
  if (existing) return  // already processed
  await db.idempotencyKey.create({ data: { key: ticket.id, processedAt: new Date() } })
  // Now process...

Why: custodial systems run on multiple servers + restart frequently.
In-memory state = zero protection against double-send.
With real money, double-send = irreversible loss.
```

### Financial state machines (Evans + Fowler)

Every financial operation is an explicit state machine. Not just a status field.

```typescript
// PayoutTicket state machine
enum PayoutTicketStatus {
  New       = 'New',        // created, not yet validated
  Prepared  = 'Prepared',   // validated, ready to send
  Processing = 'Processing', // being sent (in-flight)
  Processed = 'Processed',  // confirmed on-chain
  Failed    = 'Failed',     // terminal failure
}

// Transitions must be explicit and logged:
// New → Prepared: balance check + gas check pass
// Prepared → Processing: exclusive lock acquired
// Processing → Processed: on-chain confirmation
// Processing → Failed: after N retries exhausted

// Invalid transitions must throw:
if (ticket.status !== PayoutTicketStatus.Prepared) {
  throw new InvalidStateTransitionError(ticket.status, 'Prepared required to send')
}
```

Rules:
- Never skip states
- Always log state transitions with reason
- Terminal states (Processed, Failed) are immutable
- Processing state = distributed lock must be held

### Scheduler as domain operation

```typescript
// Anti-pattern: raw scheduler
@Cron('*/10 * * * *')
async runMergeBalance() {
  // no lock, no audit, no error tracking
}

// Correct pattern (from real project):
@Cron(CronExpression.EVERY_10_MINUTES)
async execute() {
  // 1. Distributed lock (DB or Redis — NOT in-memory)
  if (await this.settings.isLocked(LockKey.MergeBalance)) return
  await this.settings.lock(LockKey.MergeBalance)

  // 2. Session audit trail
  const session = await this.openSession('account.merge-balance', 0)

  try {
    // 3. Chunk-based processing (never process all at once)
    const accounts = await getAccounts({ take: CHUNK_SIZE })
    for (const account of accounts) {
      await processOne(account)
    }

    // 4. Close session with metrics
    await this.closeSession(session)
  } finally {
    // 5. Always release lock (even on error)
    await this.settings.unlock(LockKey.MergeBalance)
  }
}
```

### Blockchain RPC = third-party API (Boundary Rule 4 applies)

From real project: each chain has IPayoutProvider interface + concrete adapter.
This IS the Adapter pattern from `references/third-party-apis.md`.

```typescript
// Interface (domain layer — knows nothing about chain specifics)
interface IPayoutProvider {
  buildTransaction(ticket: PayoutTicket, account: PaymentAccount): Promise<RawTransaction>
  sendTransaction(ticket: PayoutTicket, account: PaymentAccount): Promise<TransactionId>
  getTransactionStatus(ticket: PayoutTicket): Promise<boolean>
}

// Adapter (infrastructure layer — chain-specific)
class EvmProvider implements IPayoutProvider { ... }
class SolanaProvider implements IPayoutProvider { ... }
class TronProvider implements IPayoutProvider { ... }

// Factory (registry — knows which adapter for which chain)
class PayoutProviderFactory {
  make(chain: ChainType): IPayoutProvider { ... }
}

// Domain service — never knows which chain it's talking to
class SendPayoutTicket {
  async execute(ticket: PayoutTicket) {
    const provider = await this.factory.make(ticket.network)  // factory decides
    const tx = await provider.sendTransaction(ticket, account) // domain doesn't know chain
  }
}
```

### Confirmation strategy by chain

```
EVM (ETH, BSC, Polygon, Base...):
  Finality: ~12-15 blocks (~2-3 min on Ethereum, seconds on L2)
  Strategy: wait for receipt + check status === 1
  Reorg risk: low on L2, medium on ETH mainnet
  Use: eth_getTransactionReceipt — status=1 AND blockNumber != null

Solana:
  Finality: 'finalized' confirmation status (~32 slots, ~13 seconds)
  Never use 'confirmed' for financial operations (can still reorg)
  Use: getSignatureStatuses → confirmationStatus === 'finalized'

TRON:
  Finality: confirmed=true AND confirmations > 20 AND contractRet === 'SUCCESS'
  Note: TRON has different confirmation model than EVM

TON:
  Finality: check lt (logical time) and seqno
  Use TonCenter API or TON Console for status

SUI:
  Finality: near-instant (single-shot BFT)
  Use: sui_getTransactionBlock — effects.status.status === 'success'
```

### Nonce management for concurrent payouts (EVM)

```
Problem: 2 concurrent payout requests from same hot wallet = same nonce = 1 fails

Solution 1 — Sequential sending (simple, recommended for low volume):
  Use DB lock or Redis SETNX to ensure only 1 payout-send runs at a time
  Process payout queue sequentially, not concurrently

Solution 2 — Nonce tracker (complex, required for high volume):
  Maintain pending_nonce in Redis per address
  INCR before signing, DECR on failure
  Reconcile with eth_getTransactionCount on startup

For most custodial wallet systems: Solution 1 is sufficient and much safer.
```

### Fund sweep (merge to hot wallet)

Pattern from real project: `schedule-merge-balance` scheduler

```
Trigger: receiver account balance > threshold (configurable, e.g. 100 USDT)
Action:
  1. Lock receiver account (no new deposits accepted during sweep)
  2. Check no pending payout tickets from this account
  3. Build sweep transaction: receiver → hot wallet
  4. Execute sweep
  5. Unlock receiver account

Risks to handle:
  - Gas fee > sweep amount (don't sweep if not profitable)
  - Sweep transaction fails (retry with backoff, not immediately)
  - Receiver gets deposit during sweep (pause deposit processing, resume after)
```

### Add to CLAUDE.md for custodial wallet

```markdown
## Custodial wallet rules

### Private key lifecycle (the private-key boundary)
Decrypt ONLY inside signing action. Clear immediately after signing.
NEVER: pass as function arg, store in property, log, return from function.
Code review must verify: no privateKey flows beyond signing action.

### Idempotency (financial operations)
All idempotency checks in DB/Redis. Never in-memory Map or boolean.
Ticket IDs are idempotency keys — check before processing, mark after.

### State machines
Every financial entity has explicit state machine.
State transitions logged with reason, timestamp, actor.
Terminal states (Processed, Failed) never transition again.

### Scheduler rules
Every scheduler: distributed lock + session audit + chunk processing.
Never process all records in one scheduler run (use chunk size).
Lock always released in finally block.

### Money amounts
All amounts in token's native decimals (wei for ETH, lamports for SOL).
Use Decimal.js or BigNumber for all arithmetic. Never native JS number.
Display formatting only at API response layer.
```
