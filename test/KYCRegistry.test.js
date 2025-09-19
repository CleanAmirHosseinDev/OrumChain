const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { deployContractsFixture } = require("./shared/fixtures");
const { MerkleTree } = require("merkletreejs");
const keccak256 = require("keccak256");
//const keccak256 = require("keccak256");

describe("KYCRegistry", function () {
  describe("Root Management", function () {
    it("should allow the KYC admin to update the Merkle root", async function () {
      const { kycRegistry, kycAdmin } = await loadFixture(deployContractsFixture);
      const newRoot = ethers.utils.randomBytes(32);

      await expect(kycRegistry.connect(kycAdmin).updateRoot(newRoot))
        .to.emit(kycRegistry, "RootUpdated")
        .withArgs(await kycRegistry.merkleRoot(), ethers.utils.hexlify(newRoot));

      expect(await kycRegistry.merkleRoot()).to.equal(ethers.utils.hexlify(newRoot));
    });

    it("should prevent a non-admin from updating the Merkle root", async function () {
      const { kycRegistry, otherUser } = await loadFixture(deployContractsFixture);
      const newRoot = ethers.utils.randomBytes(32);

      const KYC_ADMIN_ROLE = await kycRegistry.KYC_ADMIN_ROLE();
      await expect(kycRegistry.connect(otherUser).updateRoot(newRoot))
        .to.be.revertedWith(`AccessControl: account ${otherUser.address.toLowerCase()} is missing role ${KYC_ADMIN_ROLE}`);
    });
  });

  describe("Proof Verification", function () {
    it("should allow a valid user to prove their address and get verified", async function () {
      const { kycRegistry, user1, kycTree } = await loadFixture(deployContractsFixture);
      const leaf = keccak256(user1.address);
      const proof = kycTree.getHexProof(leaf);

      expect(await kycRegistry.isVerified(user1.address)).to.be.false;

      await expect(kycRegistry.connect(user1).proveAndUpdate(proof))
        .to.emit(kycRegistry, "AddressVerified")
        .withArgs(user1.address);

      expect(await kycRegistry.isVerified(user1.address)).to.be.true;
    });

    it("should not allow a user to get verified with an invalid proof", async function () {
      const { kycRegistry, user1 } = await loadFixture(deployContractsFixture);
      const invalidProof = [ethers.utils.randomBytes(32), ethers.utils.randomBytes(32)];

      await expect(kycRegistry.connect(user1).proveAndUpdate(invalidProof))
        .to.be.revertedWith("KYCR: Invalid proof");
    });

    it("should not allow an unlisted user to get verified", async function () {
      const { kycRegistry, otherUser, kycTree } = await loadFixture(deployContractsFixture);
      // This user is not in the tree, so any proof will be invalid for them.
      const leaf = keccak256(otherUser.address);
      // We use a valid proof for another user, which won't match this leaf.
      const proof = kycTree.getHexProof(keccak256((await ethers.getSigners())[5].address)); // user1's leaf

      await expect(kycRegistry.connect(otherUser).proveAndUpdate(proof))
        .to.be.revertedWith("KYCR: Invalid proof");
    });

    it("should not emit AddressVerified if user is already verified", async function () {
        const { kycRegistry, user1, kycTree } = await loadFixture(deployContractsFixture);
        const leaf = keccak256(user1.address);
        const proof = kycTree.getHexProof(leaf);

        // First verification
        await kycRegistry.connect(user1).proveAndUpdate(proof);
        expect(await kycRegistry.isVerified(user1.address)).to.be.true;

        // Second verification should not emit the event again
        await expect(kycRegistry.connect(user1).proveAndUpdate(proof))
            .to.not.emit(kycRegistry, "AddressVerified");
    });
  });
});
