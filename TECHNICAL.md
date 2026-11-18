# Agent Check-In — Technical Documentation

A daily on-chain check-in board on BNB Chain that only Agent ID holders can use.
Built for the Binance Agent ID Hackathon (submission period 18 Nov – 9 Dec 2026).

- **Live site:** https://irwansupian.github.io/agent-checkin/
- **Source code:** https://github.com/Irwansupian/agent-checkin
- **Demo video (60 s):** https://irwansupian.github.io/agent-checkin/agent-checkin-demo.mp4
- **License:** MIT

## Deployment

| Item | Value |
| --- | --- |
| Network | BNB Chain (chainId 56) |
| Contract | `0xEC64eC7F87D2706f992dB8B46d4d7Cfda92F3eE1` |
| Deploy transaction | `0x5b66e6cdb0c0888b5d516a8a418555c4f6cd8aefd8d8bb45f5824a614c94b95e` |
| BscScan | [Verified source](https://bscscan.com/address/0xEC64eC7F87D2706f992dB8B46d4d7Cfda92F3eE1#code) — verification status "Pass - Verified" |
| Compiler | Solidity 0.8.26, optimizer 200 runs, EVM cancun |
| Agent ID registry (constructor argument, immutable) | `0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F` |

## How Agent ID is used

Agent ID is not a cosmetic integration — it is the contract's only access key.

- The contract stores the official SPACE ID Agent ID registry address in an
  `immutable` variable set once in the constructor.
- Every `checkIn()` call first reads `balanceOf(msg.sender)` on that registry.
  If the balance is zero, the call reverts with the custom error
  `NotAnAgentIdHolder`. There is no other way in: no allowlist, no signature
  scheme, no admin override.
- Read helpers expose the same gate for agents and UIs: `isAgent(address)`
  returns whether an address currently holds an Agent ID.

## Contract design

`AgentCheckIn` is a single, self-contained contract with **no owner and no
privileged functions at all** — nothing can be paused, upgraded, taxed, or
withdrawn, by anyone, ever.

State per agent: `lastDay` (last check-in day), `streak` (current consecutive
days), `total` (lifetime check-ins). Global counters: `uniqueAgents`,
`totalCheckIns`. A `CheckedIn(agent, day, streak, total)` event is emitted on
every successful check-in.

Day and streak logic (all in UTC):

- `today()` = `block.timestamp / 1 days`.
- First ever check-in: streak = 1, total = 1, `uniqueAgents` increases.
- Check-in when `lastDay == today - 1`: streak grows by 1.
- Check-in after a gap of 2+ days: streak restarts at 1.
- A second check-in on the same UTC day reverts with `AlreadyCheckedInToday`.
- `streakOf(address)` reads 0 once the streak has lapsed (last check-in before
  yesterday), so UIs never show a stale streak.

Function selectors:

| Function | Selector |
| --- | --- |
| `checkIn()` | `0x183ff085` |
| `uniqueAgents()` | `0x8b5bca1e` |
| `totalCheckIns()` | `0xa563eaa3` |
| `today()` | `0xb74e452b` |
| `streakOf(address)` | `0x4fc1854a` |
| `totalOf(address)` | `0x912c2673` |

## Interaction model (agent-native, no wallet connect)

The website never connects a wallet, never asks for a signature, holds no user
sessions, and requests no token approvals. It is a read-only board plus a
copy-paste prompt for the visitor's own agent:

1. The visitor copies the prompt shown on the site to their own AI agent.
2. The agent checks the visitor's Agent ID status (`baw wallet agent-id`).
3. The agent prepares a `checkIn()` contract call through the visitor's Binance
   Agentic Wallet and shows the transaction preview.
4. The visitor confirms; only then does their own wallet sign and send.
5. The agent reads back `streakOf` / `totalOf` and reports the new streak.

This follows the hackathon's safety rules by design: every asset operation
stays inside the user's own wallet, with the user's own preview and
confirmation. A check-in costs only the BNB Chain network fee (a fraction of a
cent); the contract itself charges nothing and holds no funds.

## Verification

Anyone can verify the deployment independently:

- BscScan shows the exact-match verified source (link above).
- The deployed bytecode was reproduced locally from this repository's source
  and settings (solc 0.8.26, optimizer 200, cancun) and matched the on-chain
  code byte-for-byte, including the metadata hash, after accounting for the
  immutable registry slot.
- Example read with Foundry's `cast`:
  `cast call 0xEC64eC7F87D2706f992dB8B46d4d7Cfda92F3eE1 "isAgent(address)(bool)" <your-address> --rpc-url https://bsc-dataseed.bnbchain.org`

## Testing

Foundry unit tests (`test/AgentCheckIn.t.sol`, 4/4 passing) cover:

- a non-holder's check-in reverts;
- a holder's first check-in records streak 1 / total 1 and emits the event;
- a second same-day check-in reverts;
- the streak grows on consecutive days and lapses after a gap.

Before deployment, the contract was also deployed to a local fork of BNB Chain
and exercised against the **real** Agent ID registry: the deployer's test
wallet holding an Agent ID passed `isAgent`, and a wallet without one reverted
as designed.

## Repository layout

- `contracts/AgentCheckIn.sol` — the contract (only source file).
- `test/AgentCheckIn.t.sol` — unit tests with a mock registry.
- `index.html` — the live site (single static page, plain JSON-RPC reads).
- `README.md` — project overview.
- `LICENSE` — MIT.
