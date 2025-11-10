# Nostr MMT TigerBank Specification

Date: 2025-11-10  
Author: Glow G2  

## Overview
TigerBank is a TigerStyle-aligned payment layer that fuses Nostr identities with TigerBeetle's
debit/credit engine and embraces Modern Monetary Theory (MMT). Every user can operate a personal
central bank by minting currencies referenced by a URL-safe label:

```
~{nostr-npub}/{UserGeneratedTitle}
```

Example: `~npub1abcd...xyz/SolsticeCredits`

The label is globally unique, referentially transparent, and can be copied into contracts or QR codes.

## Components
- **Identity**: The Nostr npub anchors the issuer. Verification is handled by existing Nostr relays.
- **Ledger**: TigerBeetle maintains double-entry balances for each currency. Each ledger can expand
  or contract supply instantly under issuer control.
- **Consensus**: A Zig-native smart contract protocol inspired by Solana's Alpenglow [^alpenglow].
  It integrates Rotor-like data dissemination with one/two-round voting for fast finality.

## Zig Payload Structure
When broadcasting currency operations in non-interactive CLI mode, a typed payload is emitted:

```zig
pub const MMTCurrencyPayload = struct {
    npub: [32]u8,              // binary Nostr public key
    title: []const u8,         // UTF-8 user currency title
    policy: Policy,            // interest + tax rules
    action: Action,            // supply adjustment or loan/tax event
};

pub const Policy = struct {
    base_rate_bps: i32,        // interest rate in basis points
    tax_rate_bps: i32,         // percentage for automatic tax collection
};

pub const Action = union(enum) {
    mint: u128,                // increase supply
    burn: u128,                // decrease supply
    loan: LoanTerms,
    collect_tax: u128,
};

pub const LoanTerms = struct {
    principal: u128,
    rate_bps: i32,
    duration_seconds: u64,
};
```

This payload can be serialized to raw bytes for relay transmission or TigerBeetle posting.

## CLI Workflow
`grain conduct mmt` (interactive)
- Prompts for Nostr npub (paste or fetch from config).
- Prompts for currency title and policy parameters.
- Offers options: mint, burn, loan, collect tax.
- Confirms and submits via TigerBeetle client + Nostr relay.

`grain conduct mmt --npub=<npub> --title=<name> --mint=1000 --policy=... --cluster=host:port --relay=wss://node --emit-raw`
- Non-interactive mode. `--emit-raw` prints the serialized `MMTCurrencyPayload` for piped usage.
- `--cluster=` can be repeated to list TigerBeetle endpoints; `--relay=` can be repeated for Nostr relays.
- Without endpoints the stub still performs validation but skips network IO (emits a warning).
- TigerBank CLI uses `tigerbank_client.zig` to walk endpoints and print deterministic transmission logs until real IO hooks replace the stubs.

## Consensus Sketch
- Implement Rotor-style dissemination: each validator relays erasure-coded payload slices.
- Voting:
  - Round-one: requires 80% stake for 150 ms finality.
  - Round-two: fallback 60% stake for resilience (20% adversarial + 20% offline tolerated).
- TigerBeetle cluster ingests finalized blocks.
- Validator scheduling follows stake-weighted rotation analogous to Alpenglow's leader schedule.

## Tax & Interest
- Taxes collected automatically into issuer reserve accounts.
- Loan repayment schedules enforced by TigerBeetle tasks; overdue accounts trigger automatic rate
  hikes as defined in policy.

## Future Work
- Integrate with GUI TahoeSandbox for visual dashboards.
- Extend CLI to broadcast to multiple relays simultaneously.
- Formal verification of interest/tax smart contracts.

[^alpenglow]: Quentin Kniep, Kobi Sliwinski, Roger Wattenhofer, “Alpenglow: A New Consensus for Solana,” Anza Technology Blog, 19 May 2025. <https://www.anza.xyz/blog/alpenglow-a-new-consensus-for-solana>

