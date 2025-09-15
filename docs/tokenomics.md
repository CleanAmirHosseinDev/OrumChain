# BourseChain Gold (BCG) Tokenomics

## 1. Executive Summary

The BourseChain Gold token (BCG) is a fully collateralized, asset-backed stablecoin pegged to the value of physical gold. Each BCG token represents a direct claim on 1 gram of 999.9 purity gold, held in a secure, audited vault by a licensed custodian. The tokenomics are designed to ensure a 1:1 backing at all times, with a transparent and sustainable fee model that supports the long-term health of the ecosystem. The primary goals are stability, transparency, and deep liquidity.

## 2. On-Chain Representation

The BCG token adheres to the ERC20 standard on the zkSync network.

- **Unit of Account:** 1 BCG token = 1 gram of physical gold.
- **Decimals:** 18
- **Example:** A user holding `5.25 BCG` tokens owns a claim on 5.25 grams of gold. On-chain, this is represented as `5250000000000000000` base units (5.25 * 10^18).

## 3. Token Lifecycle State Machine

The token follows a strict lifecycle to ensure that every token in circulation is fully backed by a physical gold deposit.

```
(Start) -> [DEPOSIT] -> [ATTESTATION] -> [MINT] -> [TRADE/USE] -> [BURN] -> [REDEEM] -> (End)
```

1.  **Deposit:** A user deposits physical gold bars into the custodian's vault. The custodian verifies the weight and purity.
2.  **Attestation:** The custodian's off-chain system generates a unique, signed EIP-712 attestation containing the user's address, the amount of gold deposited, and a single-use nonce.
3.  **Mint:** The user submits this attestation to the `CustodyAttestationManager` smart contract. The contract verifies the custodian's signature and the nonce, then calls the `mint` function on the `GoldToken` contract, creating new BCG tokens for the user.
4.  **Trade/Use:** The user can now freely transfer, trade, or use their BCG tokens in DeFi applications, subject to on-chain KYC checks if enabled.
5.  **Burn:** A user wishing to redeem their gold calls the `redeem` function on the `GoldToken` contract. This burns their BCG tokens from circulation.
6.  **Redeem:** The burn transaction emits a `Redemption` event. The custodian's off-chain system listens for this event and arranges for the physical withdrawal of the corresponding amount of gold for the user, completing the cycle.

## 4. Custodian Attestation Schema (EIP-712)

This is the JSON-compatible data structure that the custodian signs to authorize a mint.

```json
{
  "types": {
    "EIP712Domain": [
      { "name": "name", "type": "string" },
      { "name": "version", "type": "string" },
      { "name": "chainId", "type": "uint256" },
      { "name": "verifyingContract", "type": "address" }
    ],
    "MintAttestation": [
      { "name": "recipient", "type": "address" },
      { "name": "amount", "type": "uint256" },
      { "name": "nonce", "type": "bytes32" }
    ]
  },
  "primaryType": "MintAttestation",
  "domain": {
    "name": "CustodyAttestation",
    "version": "1",
    "chainId": 280,
    "verifyingContract": "0x..."
  },
  "message": {
    "recipient": "0x...",
    "amount": "100000000000000000000",
    "nonce": "0x..."
  }
}
```

## 5. Fee Schedule & Revenue Projections

The protocol generates revenue from small fees on core actions. These fees are used for operational costs, security audits, and ecosystem development.

| Fee Type        | Who Pays      | Typical Rate      | Purpose                               |
| --------------- | ------------- | ----------------- | ------------------------------------- |
| **Issuance Fee**| Minter        | 0.10% - 0.20%     | Covers minting transaction & admin costs |
| **Redemption Fee**| Redeemer      | 0.25% - 0.50%     | Covers physical withdrawal & handling |
| **Trading Fee** | Trader        | 0.01% - 0.05%     | Captured from AMM pools for treasury  |

### Revenue Scenarios

**Assumptions:**
- Gold Price: $65 / gram
- Average Fee (blended): 0.15% on mint/redeem, 0.03% on trades.

---

### Scenario 1: Low Volume (Early Stage)
- **Total Supply (TVL):** 10,000 grams (~$650,000)
- **Monthly Mint/Redeem Volume:** 2,000 grams (~$130,000)
- **Monthly Trading Volume:** $1,000,000

- **Mint/Redeem Revenue:** $130,000 * 0.0015 = **$195 / month**
- **Trading Revenue:** $1,000,000 * 0.0003 = **$300 / month**
- **Total Monthly Revenue:** ~$495

---

### Scenario 2: Medium Volume (Growth Stage)
- **Total Supply (TVL):** 100,000 grams (~$6,500,000)
- **Monthly Mint/Redeem Volume:** 20,000 grams (~$1,300,000)
- **Monthly Trading Volume:** $20,000,000

- **Mint/Redeem Revenue:** $1,300,000 * 0.0015 = **$1,950 / month**
- **Trading Revenue:** $20,000,000 * 0.0003 = **$6,000 / month**
- **Total Monthly Revenue:** ~$7,950

---

### Scenario 3: High Volume (Mature Stage)
- **Total Supply (TVL):** 500,000 grams (~$32,500,000)
- **Monthly Mint/Redeem Volume:** 100,000 grams (~$6,500,000)
- **Monthly Trading Volume:** $150,000,000

- **Mint/Redeem Revenue:** $6,500,000 * 0.0015 = **$9,750 / month**
- **Trading Revenue:** $150,000,000 * 0.0003 = **$45,000 / month**
- **Total Monthly Revenue:** ~$54,750
