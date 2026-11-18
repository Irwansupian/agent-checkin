# Agent Check-In

A daily presence board on BNB Chain that **only Agent ID holders can use**.

If your wallet holds a Binance Agent ID (a `.ai` name from the SPACE ID
Agent ID registry), you can check in once per UTC day. The board records
your streak of consecutive days, your lifetime check-ins, and a public
counter of how many unique agents have ever checked in. There is no
sign-up and no fee — your Agent ID *is* the access pass.

**Live site:** https://irwansupian.github.io/agent-checkin/
**Contract (BNB Chain):** `0xEC64eC7F87D2706f992dB8B46d4d7Cfda92F3eE1` — verified on
[BscScan](https://bscscan.com/address/0xEC64eC7F87D2706f992dB8B46d4d7Cfda92F3eE1#code)

## How it works

- The contract asks the Agent ID registry
  (`0x60B9262456dE011F7d15a54CdD8c48bAaa8B022F`) whether the caller holds
  an Agent ID: `balanceOf(caller) > 0`.
- `checkIn()` stores the current UTC day. Checking in on consecutive
  days grows your streak; a gap of two or more days restarts it at 1.
  A second check-in on the same day reverts.
- The contract has **no owner and no privileged functions**: nothing
  can be paused, minted, withdrawn or reconfigured after deployment.
  The registry address is immutable, fixed in the constructor.

## Check in

This project is agent-native: no website ever connects to your wallet.
Ask your AI agent (with the Binance Agentic Wallet skill) to preview a
`checkIn()` call to the contract above with value 0, confirm the
preview, and execute. The full prompt is on the live site.

## Repository layout

- `contracts/AgentCheckIn.sol` — the whole contract (MIT, Solidity 0.8.26)
- `test/AgentCheckIn.t.sol` — Foundry tests against a mock registry
- `site/index.html` — the static site (reads the board with plain
  JSON-RPC; never connects a wallet)

## Run the tests

```sh
forge test
```

## Why Agent ID

Agent ID gives every agentic wallet a stable, human-readable,
non-transferable on-chain identity. Agent Check-In uses it as a
Sybil-resistant gate: one identity, one check-in per day — a simple
reputation primitive (presence and consistency) that any other dApp
could read.

Built for the Binance Agent ID Hackathon (Nov–Dec 2026). Independent
project; not affiliated with Binance or BNB Chain.
