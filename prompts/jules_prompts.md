# BourseChain Jules.ai Prompts

This file contains the set of prompts used to generate the BourseChain project with the Jules.ai assistant. They are stored here for reference and to facilitate future iterations and feature development.

---

### Prompt 01: Business Model & Stakeholder Map

You are a senior blockchain product architect + financial markets strategist. Produce a concise **business model & stakeholder map** for a product that tokenizes Iranian Commodity Exchange (بورس کالا) "gold warehouse receipts" (گواهی سپرده شمش طلا) and issues them as blockchain tokens on zkSync (Ethereum L2).

Return JSON with keys:
- "one_line_summary": string (max 140 chars)
- "actors": list of {role, responsibilities, trust_assumptions}
- "value_proposition": list of bullet points for each actor (custodian, retail, institutional, market_makers, regulators)
- "revenue_streams": list of {name, who_pays, typical_rate_or_fee_model}
- "primary_risks": list of {risk_name, severity(1-5), mitigation}
- "next_steps": ordered list of 6 concrete next steps (no durations) with expected deliverable file names

Be explicit about: custodian attestation, KYC provider, validator/relayer, market-maker, broker integration points, and necessity to consult Iranian commodity & securities regulation. Keep output factual and practical.

---

### Prompt 02: Token Economics (MVP)

You are a token economist and technical product writer. Design the token economics for the GoldToken MVP.

Requirements:
- Assume 1 token = 1 gram of 999.9 gold. decimals=18.
- Minting only after custodian EIP-712 attestation.
- Burning on redemption with off-chain custody flow.
- Include fee schedule examples (issuance fee, redemption fee, trading fee, settlement fee).
- Provide 3 numeric scenarios (low volume, medium, high) with example token supply, fees revenue, and custody reserve requirements. Use conservative assumptions and show all math.

Return a markdown document that contains:
1) short executive summary,
2) exact on-chain numeric representation example (how grams map to token units),
3) state machine for token lifecycle (Deposit→Attestation→Mint→Trade→Burn→Redeem),
4) sample JSON schema for custodian attestation (EIP-712 typed data),
5) list of acceptance criteria for Phase 1.

Make the answer copy-paste ready.

---

### Prompt 03: Merkle KYC Technical Spec

You are a senior smart-contract engineer. Produce a technical spec for:
A) Merkle-tree based KYC registry (off-chain provider publishes root on-chain).
B) Custodian EIP-712 attestation format & validation flow for minting.

Return:
- Short overview (3–4 sentences).
- Solidity pseudo-API for KYCRegistry contract: functions and events.
- EIP-712 typed data schemas for both: KYC root update and CustodianAttestation.
- Example Node.js (pseudo or real) scripts: generating leaves, building merkletree (merkleTreejs + keccak256), producing proof for a user.
- Solidity snippet (real code block) that uses OpenZeppelin MerkleProof.verify to verify a proof and accept a mint request.

Format: Provide code fences and a short test vector (sample input and expected verification output).

---

### Prompt 04: Core Contracts Scaffold

You are a senior Solidity developer. Generate a scaffold for the core contracts and tests.

Requirements:
- Contracts: GoldToken (ERC20 + AccessControl + Pausable + Permit/EIP-2612), KYCRegistry, CustodyAttestationManager, OracleAggregator (signed price reports).
- GoldToken must:
  - enforce Merkle KYC check on restricted transfers (configurable toggle),
  - have MINTER_ROLE for CustodyAttestationManager only,
  - support burn/redemption hook,
  - emit structured events for off-chain reconciliation.
- Provide solidity skeletons (pragma >=0.8.17) using OpenZeppelin imports (show import lines).
- Provide Hardhat + zkSync config snippet (hardhat.config.js) for compiling + deploying to zkSync testnet.
- Create 6 unit tests (Hardhat/ethers): mint with valid attestation, mint with invalid signature, transfer blocked before KYC, transfer allowed after proof, burn+redeem flow, oracle price update.

Return:
- A zip-style manifest (list of files with their contents) in JSON:
  { "files": [ { "path": "contracts/GoldToken.sol", "content": "..." }, ... ] }

Keep code concise but compile-ready. Use AccessControl, MerkleProof, and EIP-2612 patterns.

---

### Prompt 05: Derivatives Module Design

You are a derivatives protocol architect and Solidity engineer. Produce a design for offering cash-settled European options on the GoldToken.

Requirements:
- Prefer MVP architecture: off-chain matching + on-chain settlement.
- Define data model for an "option series" (underlying, strike, expiry, size, collateral type).
- Provide smart contract components and responsibilities: OptionFactory, OptionToken(ERC-1155), ClearingHouse, MarginManager.
- Define collateral model for sellers (acceptable collateral, margin ratios, liquidation triggers).
- Provide settlement pseudocode for expiry (use oracle price).
- Provide three test scenarios: buyer long call exercised in-the-money, seller covered position, seller under-collateralized and liquidated.

Return: Markdown + a JSON "API spec" for each contract (functions, events, error cases).

---

### Prompt 06: Security Audit Checklist

You are a senior smart-contract security lead. Produce an exhaustive audit checklist tailored to this system. Prioritize by severity.

Requirements:
- Include checks for: role & access controls, reentrancy, integer arithmetic, approval race conditions, oracle manipulation, attestation signature replay, Merkle proof boundary checks, upgradeability risks, proxy admin centralization, emergency pause, front-running, denial of service, gas exhaustion, time-dependency, signature malleability.
- For each item: short description, severity (Critical/High/Medium/Low), suggested fix or mitigation, example unit test or fuzz property to catch it.
- Provide recommended tools & commands (Slither, MythX, Echidna/Foundry, Certora/Scribble), and minimal CI config steps to run them.
- Provide final "go/no-go" checklist for mainnet issuance.

Return as JSON with arrays for "issues", "tools", "ci_steps", "go_no_go".

---

### Prompt 07: Deployment & Monitoring

You are a DevOps engineer for blockchain deployments. Produce:
- A Hardhat/zkSync deployment script template that reads private keys from env vars and deploys core contracts.
- Sample GitHub Actions workflow to run tests, static analysis, and auto-deploy to zkSync testnet on every merge to main branch.
- A monitoring checklist: essential on-chain events to watch, metric names, alert thresholds (price oracle variance, failed settlement, contract paused), and suggestions for Prometheus/Grafana queries or alerts.
- A short incident runbook for "oracle price outage" and "custodian attestation failure".

Return as a set of files in JSON manifest similar to Prompt 04.

---

### Prompt 08: Governance & Launch Plan

You are a token/governance strategist. Produce:
- A governance model (initial multisig/timelock → staged tokenized governance).
- On-chain governance vs off-chain governance decision matrix.
- Upgrade & emergency process: who can pause/unpause, how to propose major upgrade, required quorum.
- Phased decentralization roadmap (stakeholders & acceptance criteria for each decentralization milestone).
- Communication plan checklist for regulators, custodians, market-makers at launch.

Return as markdown and a final one-page "launch checklist" suitable for signoff.
