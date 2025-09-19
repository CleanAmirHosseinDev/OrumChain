const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
//const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");

describe("Redemption Fee Logic", function () {
  // We define a fixture to reuse the same setup in every test.
  async function deployGoldTokenFixture() {
    const [owner, user, feeCollector, otherAccount] = await ethers.getSigners();

    const GoldToken = await ethers.getContractFactory("GoldToken");
    const goldToken = await GoldToken.deploy(owner.address, owner.address);
    await goldToken.deployed();

    // Mint some tokens to the user
    await goldToken.mint(user.address, ethers.utils.parseEther("1000"));

    return { goldToken, owner, user, feeCollector, otherAccount };
  }

  describe("Fee Management", function () {
    it("should allow FEE_MANAGER_ROLE to set redemption fee", async function () {
      const { goldToken } = await loadFixture(deployGoldTokenFixture);
      await expect(goldToken.setRedemptionFee(50)).to.not.be.reverted; // 0.5%
      expect(await goldToken.redemptionFeeBps()).to.equal(50);
    });

    it("should prevent non-FEE_MANAGER_ROLE from setting redemption fee", async function () {
      const { goldToken, otherAccount } = await loadFixture(
        deployGoldTokenFixture
      );
      await expect(
        goldToken.connect(otherAccount).setRedemptionFee(50)
      ).to.be.revertedWith(/AccessControl: account .* is missing role/);
    });

    it("should prevent setting a fee greater than 100%", async function () {
      const { goldToken } = await loadFixture(deployGoldTokenFixture);
      await expect(goldToken.setRedemptionFee(10001)).to.be.revertedWith(
        "GT: Fee cannot exceed 100%"
      );
    });

    it("should allow FEE_MANAGER_ROLE to set fee collector", async function () {
      const { goldToken, feeCollector } = await loadFixture(
        deployGoldTokenFixture
      );
      await expect(goldToken.setFeeCollector(feeCollector.address)).to.not.be
        .reverted;
      expect(await goldToken.feeCollector()).to.equal(feeCollector.address);
    });

    it("should prevent non-FEE_MANAGER_ROLE from setting fee collector", async function () {
      const { goldToken, otherAccount, feeCollector } = await loadFixture(
        deployGoldTokenFixture
      );
      await expect(
        goldToken.connect(otherAccount).setFeeCollector(feeCollector.address)
      ).to.be.revertedWith(/AccessControl: account .* is missing role/);
    });

    it("should prevent setting fee collector to the zero address", async function () {
      const { goldToken } = await loadFixture(deployGoldTokenFixture);
      await expect(
        goldToken.setFeeCollector(ethers.constants.AddressZero)
      ).to.be.revertedWith("GT: Zero address");
    });
  });

  describe("Redemption with Fees", function () {
    it("should correctly apply redemption fee and burn the remainder", async function () {
      const { goldToken, user, feeCollector } = await loadFixture(
        deployGoldTokenFixture
      );

      // Set fee to 0.5% (50 bps)
      await goldToken.setRedemptionFee(50);
      await goldToken.setFeeCollector(feeCollector.address);

      const initialUserBalance = await goldToken.balanceOf(user.address);
      const initialTotalSupply = await goldToken.totalSupply();
      const redeemAmount = ethers.utils.parseEther("100");

      // Expected fee: 100 * 0.005 = 0.5 tokens
      const expectedFee = ethers.utils.parseEther("0.5");
      const expectedBurnAmount = redeemAmount.sub(expectedFee);

      await expect(goldToken.connect(user).redeem(redeemAmount))
        .to.emit(goldToken, "Redemption")
        .withArgs(user.address, expectedBurnAmount);

      const finalUserBalance = await goldToken.balanceOf(user.address);
      const finalFeeCollectorBalance = await goldToken.balanceOf(
        feeCollector.address
      );
      const finalTotalSupply = await goldToken.totalSupply();

      expect(finalUserBalance).to.equal(initialUserBalance.sub(redeemAmount));
      expect(finalFeeCollectorBalance).to.equal(expectedFee);
      expect(finalTotalSupply).to.equal(
        initialTotalSupply.sub(expectedBurnAmount)
      );
    });

    it("should revert if fee collector is not set and fee is applicable", async function () {
      const { goldToken, user } = await loadFixture(deployGoldTokenFixture);
      await goldToken.setRedemptionFee(50); // Fee is set
      // Fee collector is NOT set

      const redeemAmount = ethers.utils.parseEther("100");
      await expect(
        goldToken.connect(user).redeem(redeemAmount)
      ).to.be.revertedWith("GT: Fee collector not set");
    });

    it("should not apply a fee if the fee rate is zero", async function () {
      const { goldToken, user, feeCollector } = await loadFixture(
        deployGoldTokenFixture
      );

      // Fee is 0
      await goldToken.setRedemptionFee(0);
      await goldToken.setFeeCollector(feeCollector.address);

      const initialUserBalance = await goldToken.balanceOf(user.address);
      const initialTotalSupply = await goldToken.totalSupply();
      const redeemAmount = ethers.utils.parseEther("100");

      await expect(goldToken.connect(user).redeem(redeemAmount))
        .to.emit(goldToken, "Redemption")
        .withArgs(user.address, redeemAmount);

      const finalUserBalance = await goldToken.balanceOf(user.address);
      const finalFeeCollectorBalance = await goldToken.balanceOf(
        feeCollector.address
      );
      const finalTotalSupply = await goldToken.totalSupply();

      expect(finalUserBalance).to.equal(initialUserBalance.sub(redeemAmount));
      expect(finalFeeCollectorBalance).to.equal(0);
      expect(finalTotalSupply).to.equal(initialTotalSupply.sub(redeemAmount));
    });
  });
});
