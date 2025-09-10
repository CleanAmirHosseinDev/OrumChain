# BourseChain: A Decentralized Bridge to Physical Gold
_Version 1.0 - September 2025_

---

### **Abstract**

BourseChain is a protocol for issuing fully-collateralized, gold-backed tokens on the zkSync Layer 2 network. By tokenizing physical gold from the Iranian Commodity Exchange (IME), the BourseChain Gold token (BCG) bridges the gap between traditional hard assets and the world of decentralized finance (DeFi). The protocol leverages a hybrid on-chain/off-chain architecture to ensure regulatory compliance, security, and transparency. Through the use of EIP-712 attestations for minting and a Merkle-based KYC system, BourseChain provides a robust framework for bringing real-world asset liquidity onto the blockchain, unlocking new opportunities for investment, hedging, and commerce.

---

### **1. Introduction**

#### 1.1 The Problem: Illiquidity and Inaccessibility of Gold

Gold has been a cornerstone of global finance for millennia, valued for its stability and as a hedge against inflation. However, direct ownership of physical gold presents significant challenges for the modern investor:
- **High Friction:** Buying, selling, and storing physical gold involves high costs, logistical complexity, and reliance on centralized intermediaries.
- **Illiquidity:** Transferring ownership is slow and cumbersome, making gold unsuitable for high-frequency trading or as a medium of exchange in the digital economy.
- **Lack of Composability:** Physical gold cannot be integrated with the rapidly growing DeFi ecosystem, preventing it from being used as collateral for loans, in liquidity pools, or as a component in structured products.

#### 1.2 The Solution: The BourseChain Gold Token (BCG)

BourseChain addresses these challenges by creating a digital representation of physical gold on a scalable, low-cost Layer 2 blockchain. The BourseChain Gold token (BCG) is an ERC20 token where **1 BCG is verifiably backed by 1 gram of 999.9 purity gold**, held in a secure, audited vault.

This tokenization unlocks the latent value of gold by making it:
- **Liquid:** Instantly transferable, 24/7, anywhere in the world.
- **Accessible:** Ownership can be fractionalized, lowering the barrier to entry for all investors.
- **Composable:** As an ERC20 token, BCG can be seamlessly integrated into the entire DeFi ecosystem on zkSync and, eventually, other blockchains.

---

### **2. System Architecture**

The protocol's architecture is designed for security and scalability, with a clear separation of concerns between trusted off-chain services and immutable on-chain logic.

![Architecture Diagram](../images/architecture.svg)

#### 2.1 Off-Chain Components
- **Custodian:** A licensed and audited financial institution responsible for holding the physical gold reserves. The custodian's primary role in the protocol is to attest to new gold deposits by providing cryptographically signed EIP-712 messages.
- **KYC Provider:** A trusted, regulated entity that performs Know-Your-Customer checks on users. To preserve on-chain privacy, the provider does not publish user data directly. Instead, it publishes a Merkle root of the addresses of all verified users.

#### 2.2 On-Chain Components (zkSync)
- **GoldToken (BCG):** The core ERC20 contract representing the tokenized gold. It includes hooks to enforce KYC checks on transfers.
- **CustodyAttestationManager:** The sole entity permitted to mint new BCG tokens. It does so only after verifying a valid, single-use attestation from the custodian.
- **KYCRegistry:** A contract that stores the Merkle root from the KYC Provider. Users can interact with this contract to submit a Merkle proof and anonymously verify their KYC status.
- **OracleAggregator:** A secure price feed contract that provides the real-time price of gold, updated by a trusted oracle. This is essential for future financial products like derivatives.

---

### **3. The BourseChain Gold Token (BCG) Lifecycle**

The integrity of the 1:1 peg is maintained through a strict, auditable token lifecycle.

1.  **Minting:** A user deposits gold with the Custodian and receives a signed attestation. The user then presents this attestation to the `CustodyAttestationManager`, which verifies the signature and mints the corresponding amount of BCG tokens to the user's wallet.
2.  **Transfers:** Once minted, BCG can be transferred like any other ERC20 token. The `_beforeTokenTransfer` hook in the `GoldToken` contract checks the `KYCRegistry` to ensure that both the sender and receiver are verified, if the KYC check is enabled.
3.  **Redemption:** A user can redeem their BCG for physical gold by calling the `redeem` function. This action burns the tokens from their wallet, permanently removing them from circulation. The burn event serves as a verifiable instruction to the off-chain custodian to release the physical gold.

---

### **4. Core Technologies**

BourseChain is built on a foundation of secure and cutting-edge blockchain technologies.

- **zkSync:** By deploying on zkSync, an Ethereum Layer 2 ZK-rollup, BourseChain benefits from extremely low transaction fees and high throughput, while inheriting the security of the Ethereum mainnet.
- **EIP-712:** This Ethereum standard allows for the signing of typed, structured data instead of just cryptic hashes. This is used for custodian attestations and oracle price reports, making the signed data human-readable and less prone to phishing or error.
- **Merkle Trees:** The use of a Merkle tree for KYC allows the protocol to enforce compliance without storing any personal user data on the blockchain, providing a crucial balance between regulation and privacy.

---

### **5. Tokenomics & Fee Model**

The protocol is designed to be self-sustaining through a minimal fee model.
- **Issuance Fee (0.10% - 0.20%):** A fee on minting new tokens.
- **Redemption Fee (0.25% - 0.50%):** A fee on burning tokens to cover physical handling costs.
- **Trading Fee (0.01% - 0.05%):** A small fee that can be captured from trading activity in protocol-owned liquidity pools.

These fees are directed to the BourseChain treasury, which is used to fund ongoing development, security audits, and ecosystem growth.

---

### **6. Governance & Security**

The protocol is governed with a security-first mindset. Initially, administrative functions (like upgrading contracts or changing fees) will be controlled by a **3-of-5 Gnosis Safe Multisig** executing through a **48-hour Timelock contract**. This provides transparency and a crucial delay for the community to review any proposed changes.

In the long term, the protocol will move towards a decentralized governance model where a new governance token will empower the community to vote on economic parameters.

---

### **7. Roadmap & Future Vision**

The launch of the BCG token is the first step in a broader vision.
- **Phase 2: Liquidity & Integration:** Focus on creating deep liquidity for BCG on decentralized exchanges and integrating with DeFi lending protocols.
- **Phase 3: Derivatives & Yield:** Launch a native, cash-settled options market for BCG and explore structured products.
- **Phase 4: Decentralization:** Introduce a governance token and transition control of the protocol to a community-run DAO.

Our ultimate vision is for BCG to become a foundational building block of the DeFi ecosystem—a stable, trusted, and highly liquid asset that bridges the old world of finance with the new.

---

### **8. Conclusion**

BourseChain represents a significant step forward in the evolution of real-world asset tokenization. By combining the timeless value of gold with the power of modern blockchain technology, the protocol offers a solution that is secure, efficient, and accessible to a global audience. We invite you to join us in building the future of finance.
