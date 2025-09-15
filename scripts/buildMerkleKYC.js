const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
const { ethers } = require("ethers");

function main() {
  console.log("Building a sample Merkle Tree for the KYC whitelist...");

  // --- Sample Data ---
  // In a real system, these addresses would be sourced from a secure database of KYC-approved customers.
  const kycApprovedAddresses = [
    new ethers.Wallet(ethers.utils.randomBytes(32)).address,
    new ethers.Wallet(ethers.utils.randomBytes(32)).address,
    new ethers.Wallet(ethers.utils.randomBytes(32)).address,
    new ethers.Wallet(ethers.utils.randomBytes(32)).address,
    new ethers.Wallet(ethers.utils.randomBytes(32)).address,
  ];
  console.log("\nUsing the following addresses as the KYC whitelist:");
  console.log(kycApprovedAddresses);

  // --- Leaf Generation ---
  // The leaf is the keccak256 hash of the user's address, packed tightly.
  // This must match the leaf generation logic in the KYCRegistry.sol smart contract.
  const leaves = kycApprovedAddresses.map(addr => keccak256(addr));

  // --- Tree Construction ---
  const tree = new MerkleTree(leaves, keccak256, { sortPairs: true });
  const root = tree.getRoot().toString('hex');

  // --- Proof Generation (for the first address in the list) ---
  const addressToProve = kycApprovedAddresses[0];
  const leafToProve = keccak256(addressToProve);
  // getHexProof returns the proof as an array of hex strings, which is what the contract expects.
  const proof = tree.getHexProof(leafToProve);

  // --- Verification (off-chain check to confirm correctness) ---
  const isVerified = tree.verify(proof, leafToProve, tree.getRoot());

  // --- Output ---
  console.log("\n--- Merkle Tree Details ---");
  console.log("Merkle Root (hex):", '0x' + root);
  console.log("\nThis root should be submitted to the `updateRoot` function in the KYCRegistry contract by the KYC Admin.");

  console.log("\n--- Sample Proof (for the first address) ---");
  console.log("Address to prove:", addressToProve);
  console.log("Leaf (keccak256):", '0x' + leafToProve.toString('hex'));
  console.log("Proof (for `proveAndUpdate` function):", proof);

  console.log("\n--- Off-chain Verification Result ---");
  console.log("Is the generated proof valid against the root?", isVerified);

  if (!isVerified) {
    console.error("\n[ERROR] Off-chain verification failed! Something is wrong with the proof generation.");
  } else {
    console.log("\n[SUCCESS] Off-chain verification passed. The proof is valid.");
  }
}

main();
