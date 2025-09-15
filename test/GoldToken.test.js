const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { deployContractsFixture } = require("./shared/fixtures");
const keccak256 = require("keccak256");

describe("GoldToken System", function () {
  const ONE_HUNDRED_TOKENS = ethers.utils.parseUnits("100.0", 18);

  describe("Minting and Redemption", function () {
    it("should allow the CustodyManager to mint tokens with a valid attestation", async function () {
      const { custodyManager, goldToken, user1, getMintSignature } =
        await loadFixture(deployContractsFixture);
      const nonce = ethers.utils.randomBytes(32);
      const signature = await getMintSignature(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce
      );

      await expect(
        custodyManager.mintWithAttestation(
          user1.address,
          ONE_HUNDRED_TOKENS,
          nonce,
          signature
        )
      )
        .to.emit(goldToken, "Transfer")
        .withArgs(
          ethers.constants.AddressZero,
          user1.address,
          ONE_HUNDRED_TOKENS
        );

      expect(await goldToken.balanceOf(user1.address)).to.equal(
        ONE_HUNDRED_TOKENS
      );
    });

    it("should reject minting with an invalid signature", async function () {
      const { custodyManager, user1 } = await loadFixture(
        deployContractsFixture
      );
      const nonce = ethers.utils.randomBytes(32);

      // Use a random 65-byte hex as invalid signature
      const invalidSig = ethers.utils.hexlify(ethers.utils.randomBytes(65));

      // اصلاح: regex برای تطبیق هر نوع invalid signature
      await expect(
        custodyManager.mintWithAttestation(
          user1.address,
          ONE_HUNDRED_TOKENS,
          nonce,
          invalidSig
        )
      ).to.be.revertedWith(/invalid signature/);
    });

    it("should reject replaying a used nonce", async function () {
      const { custodyManager, user1, getMintSignature } = await loadFixture(
        deployContractsFixture
      );
      const nonce = ethers.utils.randomBytes(32);
      const signature = await getMintSignature(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce
      );

      await custodyManager.mintWithAttestation(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce,
        signature
      );

      await expect(
        custodyManager.mintWithAttestation(
          user1.address,
          ONE_HUNDRED_TOKENS,
          nonce,
          signature
        )
      ).to.be.revertedWith("CAM: Nonce already used");
    });

    it("should allow a user to redeem (burn) their tokens", async function () {
      const { custodyManager, goldToken, user1, getMintSignature } =
        await loadFixture(deployContractsFixture);
      const nonce = ethers.utils.randomBytes(32);
      const signature = await getMintSignature(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce
      );
      await custodyManager.mintWithAttestation(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce,
        signature
      );

      const redeemAmount = ethers.utils.parseUnits("30.0", 18);
      await expect(goldToken.connect(user1).redeem(redeemAmount))
        .to.emit(goldToken, "Redemption")
        .withArgs(user1.address, redeemAmount);

      expect(await goldToken.balanceOf(user1.address)).to.equal(
        ONE_HUNDRED_TOKENS.sub(redeemAmount)
      );
    });
  });

  describe("KYC-Gated Transfers", function () {
    it("should block transfers when KYC is enabled and users are not verified", async function () {
      const { goldToken, custodyManager, user1, user2, getMintSignature } =
        await loadFixture(deployContractsFixture);

      const nonce = ethers.utils.randomBytes(32);
      const signature = await getMintSignature(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce
      );
      await custodyManager.mintWithAttestation(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce,
        signature
      );

      await goldToken.setKYCCheck(true);

      await expect(
        goldToken.connect(user1).transfer(user2.address, ONE_HUNDRED_TOKENS)
      ).to.be.revertedWith("GT: sender not KYC-verified");
    });

    it("should allow transfers when KYC is enabled and both users are verified", async function () {
      const {
        goldToken,
        kycRegistry,
        custodyManager,
        user1,
        user2,
        kycTree,
        getMintSignature,
      } = await loadFixture(deployContractsFixture);

      // Mint tokens to user1 via custodyManager
      const nonce = ethers.utils.randomBytes(32);
      const signature = await getMintSignature(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce
      );
      await custodyManager.mintWithAttestation(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce,
        signature
      );

      // Users prove their addresses
      const proof1 = kycTree.getHexProof(keccak256(user1.address));
      const proof2 = kycTree.getHexProof(keccak256(user2.address));
      await kycRegistry.connect(user1).proveAndUpdate(proof1);
      await kycRegistry.connect(user2).proveAndUpdate(proof2);

      await goldToken.setKYCCheck(true);

      await expect(
        goldToken.connect(user1).transfer(user2.address, ONE_HUNDRED_TOKENS)
      ).to.not.be.reverted;
      expect(await goldToken.balanceOf(user2.address)).to.equal(
        ONE_HUNDRED_TOKENS
      );
    });
  });

  describe("EIP-2612 Permit", function () {
    it("should allow gasless approval via permit", async function () {
      const {
        goldToken,
        custodyManager,
        user1,
        otherUser,
        getMintSignature,
        getPermitSignature,
      } = await loadFixture(deployContractsFixture);

      // Mint tokens to user1 via custodyManager
      const nonce = ethers.utils.randomBytes(32);
      const signature = await getMintSignature(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce
      );
      await custodyManager.mintWithAttestation(
        user1.address,
        ONE_HUNDRED_TOKENS,
        nonce,
        signature
      );

      const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 hour
      const { v, r, s } = await getPermitSignature(
        user1,
        otherUser,
        ONE_HUNDRED_TOKENS,
        deadline
      );

      expect(
        await goldToken.allowance(user1.address, otherUser.address)
      ).to.equal(0);

      await goldToken
        .connect(otherUser)
        .permit(
          user1.address,
          otherUser.address,
          ONE_HUNDRED_TOKENS,
          deadline,
          v,
          r,
          s 
        );

      expect(
        await goldToken.allowance(user1.address, otherUser.address)
      ).to.equal(ONE_HUNDRED_TOKENS);

      await goldToken
        .connect(otherUser)
        .transferFrom(user1.address, otherUser.address, ONE_HUNDRED_TOKENS);
      expect(await goldToken.balanceOf(otherUser.address)).to.equal(
        ONE_HUNDRED_TOKENS
      );
    });
  });
});
