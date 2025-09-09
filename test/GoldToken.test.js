const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { deployContractsFixture } = require("./shared/fixtures");
const keccak256 = require("keccak256");

describe("GoldToken System", function () {
  const ONE_HUNDRED_TOKENS = ethers.utils.parseUnits("100.0", 18);
  const MAX_UINT256 = ethers.constants.MaxUint256;

  describe("Minting and Redemption", function () {
    it("should allow the CustodyManager to mint tokens with a valid attestation", async function () {
      const { custodyManager, goldToken, user1, getMintSignature } = await loadFixture(deployContractsFixture);
      const nonce = ethers.utils.randomBytes(32);
      const signature = await getMintSignature(user1.address, ONE_HUNDRED_TOKENS, nonce);

      await expect(custodyManager.mintWithAttestation(user1.address, ONE_HUNDRED_TOKENS, nonce, signature))
        .to.emit(goldToken, "Transfer")
        .withArgs(ethers.constants.AddressZero, user1.address, ONE_HUNDRED_TOKENS);

      expect(await goldToken.balanceOf(user1.address)).to.equal(ONE_HUNDRED_TOKENS);
    });

    it("should reject minting with an invalid signature", async function () {
      const { custodyManager, user1, otherUser } = await loadFixture(deployContractsFixture);
      const nonce = ethers.utils.randomBytes(32);
      // Signature from a non-custodian wallet
      const signature = await otherUser._signTypedData({}, {}, {});

      await expect(custodyManager.mintWithAttestation(user1.address, ONE_HUNDRED_TOKENS, nonce, "0x123456..."))
        .to.be.revertedWith("ECDSA: invalid signature length");
    });

    it("should reject replaying a used nonce", async function () {
      const { custodyManager, user1, getMintSignature } = await loadFixture(deployContractsFixture);
      const nonce = ethers.utils.randomBytes(32);
      const signature = await getMintSignature(user1.address, ONE_HUNDRED_TOKENS, nonce);

      await custodyManager.mintWithAttestation(user1.address, ONE_HUNDRED_TOKENS, nonce, signature);

      await expect(custodyManager.mintWithAttestation(user1.address, ONE_HUNDRED_TOKENS, nonce, signature))
        .to.be.revertedWith("CAM: Nonce already used");
    });

    it("should allow a user to redeem (burn) their tokens", async function () {
        const { custodyManager, goldToken, user1, getMintSignature } = await loadFixture(deployContractsFixture);
        const nonce = ethers.utils.randomBytes(32);
        const signature = await getMintSignature(user1.address, ONE_HUNDRED_TOKENS, nonce);
        await custodyManager.mintWithAttestation(user1.address, ONE_HUNDRED_TOKENS, nonce, signature);

        const redeemAmount = ethers.utils.parseUnits("30.0", 18);
        await expect(goldToken.connect(user1).redeem(redeemAmount))
            .to.emit(goldToken, "Redemption").withArgs(user1.address, redeemAmount);

        expect(await goldToken.balanceOf(user1.address)).to.equal(ONE_HUNDRED_TOKENS.sub(redeemAmount));
    });
  });

  describe("KYC-Gated Transfers", function () {
    it("should block transfers when KYC is enabled and users are not verified", async function () {
        const { goldToken, admin, user1, user2 } = await loadFixture(deployContractsFixture);
        // Mint tokens to user1 first (minting is not KYC-gated)
        await goldToken.connect(admin).mint(user1.address, ONE_HUNDRED_TOKENS);

        await goldToken.connect(admin).setKYCCheck(true);

        await expect(goldToken.connect(user1).transfer(user2.address, ONE_HUNDRED_TOKENS))
            .to.be.revertedWith("GT: sender not KYC-verified");
    });

    it("should allow transfers when KYC is enabled and both users are verified", async function () {
        const { goldToken, kycRegistry, admin, user1, user2, kycTree } = await loadFixture(deployContractsFixture);
        await goldToken.connect(admin).mint(user1.address, ONE_HUNDRED_TOKENS);

        // User1 proves their address
        const proof1 = kycTree.getHexProof(keccak256(user1.address));
        await kycRegistry.connect(user1).proveAndUpdate(proof1);

        // User2 proves their address
        const proof2 = kycTree.getHexProof(keccak256(user2.address));
        await kycRegistry.connect(user2).proveAndUpdate(proof2);

        await goldToken.connect(admin).setKYCCheck(true);

        await expect(goldToken.connect(user1).transfer(user2.address, ONE_HUNDRED_TOKENS))
            .to.not.be.reverted;

        expect(await goldToken.balanceOf(user2.address)).to.equal(ONE_HUNDRED_TOKENS);
    });
  });

  describe("EIP-2612 Permit", function () {
    it("should allow gasless approval via permit", async function () {
        const { goldToken, admin, user1, otherUser, getPermitSignature } = await loadFixture(deployContractsFixture);
        await goldToken.connect(admin).mint(user1.address, ONE_HUNDRED_TOKENS);

        const deadline = Math.floor(Date.now() / 1000) + 3600; // 1 hour from now
        const { v, r, s } = await getPermitSignature(user1, otherUser, ONE_HUNDRED_TOKENS, deadline);

        expect(await goldToken.allowance(user1.address, otherUser.address)).to.equal(0);

        // The relayer (otherUser) submits the permit
        await goldToken.connect(otherUser).permit(user1.address, otherUser.address, ONE_HUNDRED_TOKENS, deadline, v, r, s);

        expect(await goldToken.allowance(user1.address, otherUser.address)).to.equal(ONE_HUNDRED_TOKENS);

        // The relayer can now transfer the funds
        await goldToken.connect(otherUser).transferFrom(user1.address, otherUser.address, ONE_HUNDRED_TOKENS);
        expect(await goldToken.balanceOf(otherUser.address)).to.equal(ONE_HUNDRED_TOKENS);
    });
  });
});
