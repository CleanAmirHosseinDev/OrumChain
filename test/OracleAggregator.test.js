const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
const { deployContractsFixture } = require("./shared/fixtures");
//const { deployContractsFixture } = require("./shared/fixtures");

describe("OracleAggregator", function () {
  const getOracleSignature = async (oracleSigner, contractAddress, price, timestamp) => {
    const domain = {
      name: "OracleAggregator",
      version: "1",
      chainId: (await ethers.provider.getNetwork()).chainId,
      verifyingContract: contractAddress,
    };
    const types = {
      PriceReport: [
        { name: "price", type: "uint256" },
        { name: "timestamp", type: "uint256" },
      ],
    };
    const value = { price, timestamp };
    return await oracleSigner._signTypedData(domain, types, value);
  };

  it("should allow a valid oracle to update the price", async function () {
    const { oracleAggregator, oracle } = await loadFixture(deployContractsFixture);
    const newPrice = ethers.utils.parseUnits("65.50", 18); // $65.50 per gram
    const timestamp = Math.floor(Date.now() / 1000) + 1;

    const signature = await getOracleSignature(oracle, oracleAggregator.address, newPrice, timestamp);

    await expect(oracleAggregator.updatePrice(newPrice, timestamp, signature))
      .to.emit(oracleAggregator, "PriceUpdated")
      .withArgs(newPrice, timestamp, oracle.address);

    expect(await oracleAggregator.latestPrice()).to.equal(newPrice);
    expect(await oracleAggregator.lastUpdateTimestamp()).to.equal(timestamp);
  });

  it("should prevent a non-oracle from updating the price", async function () {
    const { oracleAggregator, otherUser } = await loadFixture(deployContractsFixture);
    const newPrice = ethers.utils.parseUnits("66.00", 18);
    const timestamp = Math.floor(Date.now() / 1000) + 1;

    // Signature from an unauthorized wallet
    const signature = await getOracleSignature(otherUser, oracleAggregator.address, newPrice, timestamp);

    await expect(oracleAggregator.updatePrice(newPrice, timestamp, signature))
      .to.be.revertedWith("OA: Invalid oracle signature");
  });

  it("should prevent updates with a stale timestamp", async function () {
    const { oracleAggregator, oracle } = await loadFixture(deployContractsFixture);

    // First successful update
    const price1 = ethers.utils.parseUnits("65.00", 18);
    const timestamp1 = Math.floor(Date.now() / 1000) + 1;
    const signature1 = await getOracleSignature(oracle, oracleAggregator.address, price1, timestamp1);
    await oracleAggregator.updatePrice(price1, timestamp1, signature1);

    // Second update attempt with the same timestamp
    const price2 = ethers.utils.parseUnits("65.01", 18);
    const signature2 = await getOracleSignature(oracle, oracleAggregator.address, price2, timestamp1);
    await expect(oracleAggregator.updatePrice(price2, timestamp1, signature2))
      .to.be.revertedWith("OA: Stale timestamp");

    // Third update attempt with an older timestamp
    const price3 = ethers.utils.parseUnits("65.02", 18);
    const timestamp3 = timestamp1 - 10;
    const signature3 = await getOracleSignature(oracle, oracleAggregator.address, price3, timestamp3);
    await expect(oracleAggregator.updatePrice(price3, timestamp3, signature3))
        .to.be.revertedWith("OA: Stale timestamp");
  });
});
