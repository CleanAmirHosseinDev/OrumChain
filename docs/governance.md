# BourseChain Governance Model

This document outlines the governance structure for the BourseChain protocol, detailing the initial secure administrative setup and the path toward progressive decentralization.

## Guiding Principles

- **Security First:** The governance model prioritizes the safety of user funds and the stability of the protocol above all else.
- **Transparency:** All administrative actions and proposals will be public and verifiable on-chain.
- **Progressive Decentralization:** The protocol will gradually transfer control from the founding team to a decentralized community of stakeholders as the system matures.

## Phase 1: Initial Governance (Multisig + Timelock)

At launch and during the initial growth phases, the protocol will be administered by a secure, multi-layered structure based on industry best practices.

### Components:
1.  **Gnosis Safe (Multisig):** A 3-of-5 multisignature wallet will serve as the root administrative authority. The signers will be key stakeholders and trusted security professionals from the BourseChain team and its partners. This ensures no single individual can control the system.
2.  **TimelockController:** An OpenZeppelin `TimelockController` contract will be the direct owner of all administrative functions in the protocol. All actions proposed by the Gnosis Safe must pass through this timelock.

### Administrative Flow:
1.  **Proposal:** An action (e.g., upgrading a contract, changing a fee) is proposed by a multisig owner.
2.  **Approval:** At least 3 of the 5 multisig owners must sign the transaction.
3.  **Scheduling:** The multisig executes a transaction that calls `schedule()` on the `TimelockController`. The proposed action is now publicly queued.
4.  **Time Delay:** A mandatory `minDelay` (e.g., 48 hours) must pass. This delay acts as a crucial safeguard, giving the community time to review the proposed change and react if it is malicious or incorrect.
5.  **Execution:** After the delay, anyone can call `execute()` on the `TimelockController` to enact the change.

### Role Breakdown:
- **`DEFAULT_ADMIN_ROLE` (on all contracts):** Owned by the `TimelockController` contract.
- **`PROPOSER_ROLE` (on TimelockController):** Owned by the Gnosis Safe multisig. This is the only role that can schedule new actions.
- **`EXECUTOR_ROLE` (on TimelockController):** Granted to `address(0)` (everyone). This allows for permissionless execution of proposals that have passed their time delay.
- **`CANCELLER_ROLE` (on TimelockController):** Owned by the Gnosis Safe multisig. This allows the multisig to cancel a queued proposal if a mistake is found during the time delay period.

## Emergency Procedures

- **Pause Functionality:** The `PAUSER_ROLE` on the `GoldToken` contract will be held by the Gnosis Safe directly (bypassing the timelock). This allows the team to pause all token transfers in the event of a critical vulnerability or economic attack, providing a rapid response mechanism to protect user funds. Unpausing will still be subject to the timelock.
- **Oracle Outage:** In the event of an oracle failure, the derivatives module (`ClearingHouse`) will have a safety mechanism to pause liquidations and new position openings until the oracle feed is restored.

## Phase 2: Staged Decentralization (DAO Governance)

As outlined in the [Roadmap](./roadmap.md), the long-term goal is to introduce a governance token (`BRC`) and transition control to a Decentralized Autonomous Organization (DAO).

- **On-Chain vs. Off-Chain:**
  - **On-Chain:** The DAO will directly control economic parameters via on-chain voting. This includes setting fee percentages, adding new collateral types, and managing the protocol treasury.
  - **Off-Chain (Snapshot):** Larger, more complex proposals, such as major architectural changes or strategic initiatives, may use off-chain voting (e.g., Snapshot) for signaling before being implemented by the core team via the timelock process.

- **Upgrade Process:** Major contract upgrades will always remain under the purview of the core team, executed through the timelock for maximum security. The DAO may signal its approval for an upgrade, but the final execution will be handled by the multisig to prevent governance attacks from compromising the core protocol logic.

- **Quorum:** A minimum quorum (e.g., 4% of total token supply) will be required for a vote to be considered valid, preventing a small minority from controlling the protocol. A simple majority will be required for a proposal to pass.
