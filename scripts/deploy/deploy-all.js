const { Wallet } = require("zksync-web3");
const { Deployer } = require("@matterlabs/hardhat-zksync-deploy");
const ethers = require("ethers");
require("dotenv").config();

async function main(hre) {
  console.log(`\nRunning deploy script for BourseChain contracts...`);

  // --- 1. Initialize Deployer ---
  const deployerPrivateKey = process.env.DEPLOYER_PRIVATE_KEY;
  if (!deployerPrivateKey) {
    throw new Error("DEPLOYER_PRIVATE_KEY is not set in .env file.");
  }
  const wallet = new Wallet(deployerPrivateKey);
  const deployer = new Deployer(hre, wallet);
  const adminAddress = wallet.address;
  console.log(`Deployer address: ${adminAddress}`);

  // --- 2. Load Artifacts ---
  const kycRegistryArtifact = await deployer.loadArtifact("KYCRegistry");
  const goldTokenArtifact = await deployer.loadArtifact("GoldToken");
  const custodyManagerArtifact = await deployer.loadArtifact("CustodyAttestationManager");
  const oracleAggregatorArtifact = await deployer.loadArtifact("OracleAggregator");

  // --- 3. Deploy Contracts ---
  console.log("\nDeploying contracts...");

  // Deploy KYCRegistry
  const initialKycRoot = "0x0000000000000000000000000000000000000000000000000000000000000000";
  const kycRegistry = await deployer.deploy(kycRegistryArtifact, [adminAddress, initialKycRoot]);
  console.log(`-> KYCRegistry deployed to: ${kycRegistry.address}`);

  // Deploy CustodyAttestationManager and GoldToken
  // We need the manager address for the GoldToken constructor to grant MINTER_ROLE
  const custodyManager = await deployer.deploy(custodyManagerArtifact, [adminAddress, ethers.constants.AddressZero]); // Deploy with placeholder token address
  console.log(`-> CustodyAttestationManager (temp) deployed to: ${custodyManager.address}`);

  const goldToken = await deployer.deploy(goldTokenArtifact, [adminAddress, custodyManager.address]);
  console.log(`-> GoldToken deployed to: ${goldToken.address}`);

  // This is a workaround for constructor interdependency. We deploy the manager with a zero address,
  // then deploy the token with the manager's address, then we would need to set the token address
  // in the manager. My current CustodyAttestationManager uses an immutable address, which is better.
  // So, the deployment order should be Token -> Manager. Let's adjust.
  // The best pattern is: Deploy Token with a placeholder minter. Deploy Manager with token address. Grant minter role to Manager. Revoke from placeholder.

  // Re-doing deployment logic for clarity and correctness.
  console.log("\nRe-running deployment with correct dependency order...");

  // Deploy GoldToken with a placeholder minter address (the deployer itself for now)
  const goldToken_re = await deployer.deploy(goldTokenArtifact, [adminAddress, adminAddress]);
  console.log(`-> GoldToken deployed to: ${goldToken_re.address}`);

  // Deploy CustodyAttestationManager with the correct GoldToken address
  const custodyManager_re = await deployer.deploy(custodyManagerArtifact, [adminAddress, goldToken_re.address]);
  console.log(`-> CustodyAttestationManager deployed to: ${custodyManager_re.address}`);

  // Deploy OracleAggregator
  const oracleAddress = process.env.ORACLE_ADDRESS || wallet.address; // Use deployer if not set
  const oracleAggregator = await deployer.deploy(oracleAggregatorArtifact, [adminAddress, oracleAddress]);
  console.log(`-> OracleAggregator deployed to: ${oracleAggregator.address}`);

  // --- 4. Post-Deployment Configuration ---
  console.log("\nConfiguring roles and contract links...");

  // Grant MINTER_ROLE to CustodyAttestationManager
  const minterRole = await goldToken_re.MINTER_ROLE();
  let tx = await goldToken_re.grantRole(minterRole, custodyManager_re.address);
  await tx.wait();
  console.log(`- MINTER_ROLE granted to CustodyAttestationManager.`);

  // Revoke MINTER_ROLE from the initial placeholder (admin)
  tx = await goldToken_re.revokeRole(minterRole, adminAddress);
  await tx.wait();
  console.log(`- MINTER_ROLE revoked from deployer/admin.`);

  // Set KYC Registry in GoldToken
  tx = await goldToken_re.setKYCRegistry(kycRegistry.address);
  await tx.wait();
  console.log(`- KYCRegistry address set in GoldToken.`);

  // Grant CUSTODIAN_ROLE in CustodyAttestationManager
  const custodianAddress = process.env.CUSTODIAN_ADDRESS || wallet.address; // Use deployer if not set
  const custodianRole = await custodyManager_re.CUSTODIAN_ROLE();
  tx = await custodyManager_re.grantRole(custodianRole, custodianAddress);
  await tx.wait();
  console.log(`- CUSTODIAN_ROLE granted to ${custodianAddress}.`);

  // --- 5. Final Summary ---
  console.log("\n--- Deployment Summary ---");
  console.log(`KYCRegistry:                ${kycRegistry.address}`);
  console.log(`GoldToken:                  ${goldToken_re.address}`);
  console.log(`CustodyAttestationManager:  ${custodyManager_re.address}`);
  console.log(`OracleAggregator:           ${oracleAggregator.address}`);
  console.log("--------------------------\n");

  return {
    kycRegistry,
    goldToken: goldToken_re,
    custodyManager: custodyManager_re,
    oracleAggregator
  };
}

// This wrapper is used to make sure that the script can be run directly with `npx hardhat deploy-zksync`
// or imported into other scripts.
if (require.main === module) {
  const hre = require("hardhat");
  main(hre).catch((error) => {
    console.error(error);
    process.exit(1);
  });
}

module.exports = main;
