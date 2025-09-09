const { ethers } = require("hardhat");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");

async function deployContractsFixture() {
  // --- Get Signers ---
  const [admin, custodian, oracle, kycAdmin, user1, user2, otherUser] = await ethers.getSigners();

  // --- 1. Deploy KYCRegistry ---
  const kycLeafAddresses = [user1.address, user2.address];
  const kycLeaves = kycLeafAddresses.map(addr => keccak256(addr));
  const kycTree = new MerkleTree(kycLeaves, keccak256, { sortPairs: true });
  const kycRoot = kycTree.getHexRoot();
  const KYCRegistryFactory = await ethers.getContractFactory("KYCRegistry");
  const kycRegistry = await KYCRegistryFactory.connect(admin).deploy(kycAdmin.address, kycRoot);

  // --- 2. Deploy GoldToken and Manager ---
  const GoldTokenFactory = await ethers.getContractFactory("GoldToken");
  const CustodyAttestationManagerFactory = await ethers.getContractFactory("CustodyAttestationManager");

  // Deploy GoldToken with admin as a placeholder minter
  const goldToken = await GoldTokenFactory.connect(admin).deploy(admin.address, admin.address);
  // Deploy Manager with the real GoldToken address
  const custodyManager = await CustodyAttestationManagerFactory.connect(admin).deploy(admin.address, goldToken.address);

  // --- 3. Deploy Oracle ---
  const OracleAggregatorFactory = await ethers.getContractFactory("OracleAggregator");
  const oracleAggregator = await OracleAggregatorFactory.connect(admin).deploy(admin.address, oracle.address);

  // --- 4. Configure Roles & Links ---
  const MINTER_ROLE = await goldToken.MINTER_ROLE();
  await goldToken.connect(admin).grantRole(MINTER_ROLE, custodyManager.address);
  // FIX: Corrected typo from goldToke to goldToken
  await goldToken.connect(admin).revokeRole(MINTER_ROLE, admin.address);

  await goldToken.connect(admin).setKYCRegistry(kycRegistry.address);

  const CUSTODIAN_ROLE = await custodyManager.CUSTODIAN_ROLE();
  await custodyManager.connect(admin).grantRole(CUSTODIAN_ROLE, custodian.address);

  const KYC_ADMIN_ROLE = await kycRegistry.KYC_ADMIN_ROLE();
  await kycRegistry.connect(admin).grantRole(KYC_ADMIN_ROLE, kycAdmin.address);


  // --- EIP-712 Helper Functions ---
  const getMintSignature = async (recipient, amount, nonce) => {
    const domain = {
      name: "CustodyAttestation",
      version: "1",
      chainId: (await ethers.provider.getNetwork()).chainId,
      verifyingContract: custodyManager.address,
    };
    const types = {
      MintAttestation: [
        { name: "recipient", type: "address" },
        { name: "amount", type: "uint256" },
        { name: "nonce", type: "bytes32" },
      ],
    };
    const value = { recipient, amount, nonce };
    return await custodian._signTypedData(domain, types, value);
  };

  const getPermitSignature = async (owner, spender, value, deadline) => {
      const nonce = await goldToken.nonces(owner.address);
      const domain = {
          name: await goldToken.name(),
          version: '1',
          chainId: (await ethers.provider.getNetwork()).chainId,
          verifyingContract: goldToken.address,
      };
      const types = {
          Permit: [
              { name: 'owner', type: 'address' },
              { name: 'spender', type: 'address' },
              { name: 'value', type: 'uint256' },
              { name: 'nonce', type: 'uint256' },
              { name: 'deadline', type: 'uint256' },
          ],
      };
      const signature = await owner._signTypedData(domain, types, { owner: owner.address, spender: spender.address, value, nonce, deadline });

      const { v, r, s } = ethers.utils.splitSignature(signature);
      return { v, r, s };
  };


  return {
    goldToken,
    kycRegistry,
    custodyManager,
    oracleAggregator,
    admin,
    custodian,
    oracle,
    kycAdmin,
    user1,
    user2,
    otherUser,
    kycTree,
    getMintSignature,
    getPermitSignature
  };
}

module.exports = { deployContractsFixture };
