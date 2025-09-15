# BourseChain Development Roadmap

This document outlines the phased development and strategic goals for the BourseChain project. Each phase builds upon the last, progressively adding functionality and decentralizing control.

---

### Phase 1: MVP Launch & Core Functionality (Current)

**Goal:** Launch a secure, audited, and functional platform for tokenizing gold on zkSync.

**Key Deliverables:**
- ✅ **Core Smart Contracts:** `GoldToken` (ERC20), `CustodyAttestationManager`, `KYCRegistry`, and `OracleAggregator`.
- ✅ **Secure Custody:** Integration with a licensed, insured custodian for physical gold reserves.
- ✅ **Off-Chain KYC:** A robust process for user verification managed by a trusted KYC provider.
- ✅ **Audits:** Completion of at least one full security audit from a reputable firm.
- ✅ **Basic dApp:** A simple web interface for viewing balances and initiating mint/redeem processes.
- **Acceptance Criteria:** Users can successfully mint new BCG tokens against deposited gold and redeem tokens for physical gold in a secure, verifiable manner.

---

### Phase 2: Liquidity & Integrations

**Goal:** Establish deep liquidity for the BCG token and integrate with the broader DeFi ecosystem.

**Key Deliverables:**
- **AMM Integration:** Create and seed liquidity pools on major zkSync DEXs (e.g., SyncSwap, Mute.io).
- **Yield Farming:** Launch liquidity mining programs to incentivize early liquidity providers.
- **Broker Integration:** Develop APIs and partnerships to allow traditional brokers and financial institutions to offer tokenized gold to their clients.
- **Wallet Support:** Ensure BCG is listed and recognized by major web3 wallets.
- **Acceptance Criteria:** BCG maintains a stable peg to the price of gold with low slippage on trades up to a significant size (e.g., $100,000).

---

### Phase 3: Derivatives & Yield Products

**Goal:** Expand the utility of BCG by building a native derivatives market and yield-generating products.

**Key Deliverables:**
- **Options Module Launch:** Full implementation and launch of the off-chain matching, on-chain settlement European options module (based on the `OptionFactory` and `ClearingHouse` skeletons).
- **Collateral Expansion:** Allow BCG to be used as collateral for other assets within the BourseChain ecosystem and on partner lending platforms.
- **Structured Products:** Explore the creation of simple structured products, such as fixed-yield vaults or principal-protected notes using BCG.
- **Acceptance Criteria:** Users can successfully trade cash-settled options on BCG, and the token is accepted as high-quality collateral on at least one major DeFi lending protocol.

---

### Phase 4: Progressive Decentralization

**Goal:** Transition control of the protocol's economic parameters and non-critical functions to a decentralized governance model.

**Key Deliverables:**
- **Governance Token Launch:** Introduction of a new governance token (e.g., `BRC`) to be distributed to early users, liquidity providers, and the community.
- **On-Chain Governance:** Implementation of a governance module where BRC token holders can vote on proposals.
- **Parameter Control:** Delegate control over fee switches, collateral types, and other economic parameters to on-chain governance.
- **Treasury Management:** The protocol's revenue-generating treasury will be managed by the DAO.
- **Acceptance Criteria:** The DAO can successfully pass and execute a proposal to change a protocol fee. Core upgradeability and security functions remain under the control of a timelocked multisig managed by the founding team for security.
