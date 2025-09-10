# BourseChain Security Audit Checklist

This document provides an exhaustive checklist for auditing the BourseChain smart contracts. It is intended for use by internal developers and external security researchers.

## Recommended Tools & Setup

- **Static Analysis:**
  - **Slither:** `slither . --solc-remaps "@openzeppelin=node_modules/@openzeppelin"`
- **Fuzzing & Property-Based Testing:**
  - **Echidna/Foundry:** Write properties to test invariants (e.g., total supply should never decrease except during a burn).
- **Formal Verification:**
  - **Certora/Scribble:** Annotate contracts with specifications and run the Certora Prover. `scribble instrument --arm --contracts <ContractName>`

---

## High-Priority Checklist

### C01: Oracle Manipulation & Price Staleness
- **Description:** The `ClearingHouse` and other potential future modules rely on the `OracleAggregator` for pricing. A malicious or faulty oracle could provide an incorrect price, leading to unfair liquidations or settlements.
- **Severity:** Critical
- **Mitigation:**
  - The `OracleAggregator` uses EIP-712 signature verification, ensuring only whitelisted oracles (`ORACLE_ROLE`) can submit prices.
  - The `updatePrice` function requires a strictly increasing timestamp to prevent replay attacks.
  - **Future Improvement:** Implement a multi-oracle system with aggregation logic (e.g., medianizer) to reduce reliance on a single price source. Add heartbeat checks to ensure the price is not stale.
- **Test Case:**
  - `test/OracleAggregator.test.js`: "should prevent updates with a stale timestamp".
  - Fuzz test: `fuzz_updatePrice` where the timestamp is varied randomly around the last update time.

### C02: Incorrect Access Control
- **Description:** Sensitive functions like minting, pausing, or updating critical addresses must be strictly controlled.
- **Severity:** Critical
- **Mitigation:**
  - OpenZeppelin `AccessControl` is used extensively.
  - Roles (`MINTER_ROLE`, `PAUSER_ROLE`, `KYC_ADMIN_ROLE`, etc.) are defined as `bytes32` constants.
  - The `onlyRole` modifier is applied to all sensitive functions.
  - Administrative control is intended to be managed by a `TimelockController` and Multisig.
- **Test Case:**
  - `test/KYCRegistry.test.js`: "should prevent a non-admin from updating the Merkle root".
  - Attempt to call every `onlyRole` function from an account without that role and assert that it reverts.

### C03: Custodian Attestation Replay / Forgery
- **Description:** An attacker could attempt to replay a valid minting attestation or forge a new one.
- **Severity:** Critical
- **Mitigation:**
  - `CustodyAttestationManager` uses EIP-712, which includes the contract's address and chain ID in the signature hash, preventing cross-chain replay.
  - A `usedNonces` mapping ensures that each attestation (identified by its unique nonce) can only be used once.
- **Test Case:**
  - `test/GoldToken.test.js`: "should reject replaying a used nonce".

---

## Medium-Priority Checklist

### M01: Reentrancy in Redemption/Withdrawal
- **Description:** A malicious contract could call `redeem` and, through a callback (e.g., `onERC721Received` if the token were an NFT, or via a fallback function), re-enter the function to drain funds before the balance state is updated.
- **Severity:** High
- **Mitigation:**
  - The `redeem` function in `GoldToken.sol` uses OpenZeppelin's `ReentrancyGuard` (`nonReentrant` modifier).
  - The Checks-Effects-Interactions pattern is followed (state is updated before external calls, though `_burn` has no external calls).
- **Test Case:**
  - Create a malicious contract that implements a `receive()` or `fallback()` function which calls back into `redeem`. Attempt to call `redeem` from this contract and assert that it reverts.

### M02: KYC Proof Forgery
- **Description:** A user could try to generate a valid proof for their address without being on the official KYC list.
- **Severity:** High
- **Mitigation:**
  - The strength of the Merkle proof system relies on the secrecy of the full list of whitelisted addresses.
  - The `KYCRegistry` contract correctly verifies the provided proof against the on-chain `merkleRoot`. The leaf is derived from `msg.sender`, preventing a user from submitting a valid proof for another user's address.
- **Test Case:**
  - `test/KYCRegistry.test.js`: "should not allow an unlisted user to get verified".

### M03: Integer Overflow/Underflow
- **Description:** Unchecked arithmetic could lead to integer overflows or underflows.
- **Severity:** Medium (since Solidity >=0.8.0)
- **Mitigation:**
  - The project uses `pragma solidity ^0.8.17;`. All arithmetic operations in Solidity 8.x and above automatically revert on overflow or underflow. No `SafeMath` library is needed.
- **Test Case:**
  - Standard unit tests covering balance changes implicitly test this. For example, attempting to burn more tokens than a user has will revert due to underflow.

---

## Low-Priority / Informational

### L01: Gas Exhaustion / Denial of Service
- **Description:** Unbounded loops in contracts could lead to gas exhaustion, making certain functions unusable.
- **Severity:** Low
- **Mitigation:**
  - The codebase avoids unbounded loops. All loops are over fixed-size arrays or have clear termination conditions.
  - The `proveAndUpdate` function in `KYCRegistry` operates on a user-provided proof, not by iterating over an on-chain list.
- **Test Case:**
  - Test functions with large, but plausible, inputs to ensure they do not run out of gas within the block gas limit.

### L02: Signature Malleability (EIP-2612 Permit)
- **Description:** The `permit` function relies on ECDSA signatures, which can sometimes be malleable (producing a different valid signature for the same message).
- **Severity:** Low
- **Mitigation:**
  - OpenZeppelin's `ERC20Permit` implementation is robust against known signature malleability issues by using `ecrecover` correctly and checking the recovered address.
- **Test Case:**
  - `test/GoldToken.test.js` has a positive test case for `permit`. A negative test could involve manipulating the `v`, `r`, `s` values of a valid signature and asserting that it fails.

### L03: Centralization Risks
- **Description:** In the initial phase, roles like `KYC_ADMIN_ROLE` and `ORACLE_ROLE` are centralized.
- **Severity:** Informational (Acknowledged Risk)
- **Mitigation:**
  - This is a deliberate trade-off for security and agility in the early stages.
  - The `docs/governance.md` file clearly outlines the plan for progressive decentralization, including the use of a Timelock and Multisig to mitigate single-person control.
- **Test Case:**
  - Not applicable (this is an architectural review point).
