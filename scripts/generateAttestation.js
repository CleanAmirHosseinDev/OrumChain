const { ethers } = require("ethers");
require("dotenv").config();

async function main() {
  console.log("Generating a sample EIP-712 Mint Attestation...");

  const custodianPrivateKey = process.env.CUSTODIAN_PRIVATE_KEY;
  if (!custodianPrivateKey) {
    throw new Error("CUSTODIAN_PRIVATE_KEY is not set in .env file. Please set it to a valid private key.");
  }
  const custodianWallet = new ethers.Wallet(custodianPrivateKey);

  // --- Configuration ---
  // TODO: Replace with the deployed CustodyAttestationManager contract address after deployment.
  const managerContractAddress = "0x0000000000000000000000000000000000000000";
  // The chain ID for the target network (e.g., 280 for zkSync Testnet)
  const chainId = 280;

  // --- EIP-712 Domain ---
  const domain = {
    name: "CustodyAttestation",
    version: "1",
    chainId: chainId,
    verifyingContract: managerContractAddress,
  };

  // --- EIP-712 Types ---
  const types = {
    MintAttestation: [
      { name: "recipient", type: "address" },
      { name: "amount", type: "uint256" },
      { name: "nonce", type: "bytes32" },
    ],
  };

  // --- Attestation Data ---
  const attestationData = {
    // TODO: Replace with the actual recipient's address.
    recipient: "0x1234567890123456789012345678901234567890",
    amount: ethers.utils.parseUnits("100.0", 18), // Example: 100 grams of gold
    nonce: ethers.utils.randomBytes(32),
  };

  // --- Signing ---
  console.log("Signing attestation with custodian key:", custodianWallet.address);
  const signature = await custodianWallet._signTypedData(domain, types, attestationData);

  // --- Output ---
  console.log("\n--- Generated Attestation ---");
  console.log("To be used with CustodyAttestationManager at:", managerContractAddress);
  console.log("\nParameters for `mintWithAttestation` function:");
  console.log(`recipient: "${attestationData.recipient}"`);
  console.log(`amount: "${attestationData.amount.toString()}"`);
  console.log(`nonce: "${ethers.utils.hexlify(attestationData.nonce)}"`);
  console.log(`signature: "${signature}"`);
  console.log("\nNote: Ensure the 'managerContractAddress' and 'chainId' are correct before using.");
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
