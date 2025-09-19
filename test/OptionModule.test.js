const { expect } = require("chai");
const { ethers } = require("hardhat");
const { loadFixture } = require("@nomicfoundation/hardhat-network-helpers");
// Note: The main fixture would need to be extended to deploy the options contracts.
const { deployContractsFixture } = require("./shared/fixtures");

// These tests are skipped as the contracts are just skeletons.
// They serve as a blueprint for future implementation.
describe.skip("Option Module", function () {
  async function deployOptionModuleFixture() {
    const baseFixture = await loadFixture(deployContractsFixture);

    // TODO: Deploy OptionFactory, OptionToken, and ClearingHouse here
    // and link them together.

    // Example:
    // const OptionTokenFactory = await ethers.getContractFactory("OptionToken");
    // const optionToken = await OptionTokenFactory.deploy(...);
    // ...etc.

    return { ...baseFixture /*, optionToken, optionFactory, clearingHouse */ };
  }

  describe("OptionFactory", function () {
    it.skip("should allow an admin to create a new option series", async function () {
      // 1. Load fixture
      // 2. Define series parameters (underlying, strike, expiry, isPut)
      // 3. Call createOptionSeries
      // 4. Expect a SeriesCreated event to be emitted with correct parameters
    });

    it.skip("should prevent a non-admin from creating a new option series", async function () {
      // 1. Load fixture
      // 2. Call createOptionSeries from a non-admin account
      // 3. Expect the transaction to be reverted with an AccessControl error
    });

    it.skip("should prevent creating a series that already exists", async function () {
      // 1. Load fixture
      // 2. Create a series
      // 3. Attempt to create the exact same series again
      // 4. Expect the transaction to be reverted
    });
  });

  describe("ClearingHouse", function () {
    describe("Collateral Management", function () {
      it.skip("should allow a user to deposit collateral", async function () {
        // 1. Load fixture
        // 2. Mint some collateral tokens (e.g., a mock USDC) to the user
        // 3. User approves the ClearingHouse to spend the collateral
        // 4. User calls depositCollateral
        // 5. Expect the user's collateral balance in the contract to be updated
        // 6. Expect the contract's token balance to increase
      });

      it.skip("should allow a user to withdraw collateral if their position is safe", async function () {
        // 1. Deposit collateral first
        // 2. User calls withdrawCollateral
        // 3. Check that their position is still sufficiently collateralized
        // 4. Expect balances to be updated correctly
      });
    });

    describe("Settlement", function () {
      it.skip("should correctly settle an in-the-money call option", async function () {
        // 1. Create a call option series
        // 2. A seller deposits collateral and mints the option tokens (long and short)
        // 3. A buyer acquires the long token
        // 4. Fast-forward time past the expiry date
        // 5. Set the oracle price to be above the strike price
        // 6. Call settleExpiredOption
        // 7. Expect the buyer's collateral balance to increase by the payout
        // 8. Expect the seller's collateral balance to decrease by the payout
        // 9. Expect the option tokens to be burned
      });

      it.skip("should correctly settle an out-of-the-money call option", async function () {
        // 1. Same setup as above
        // 2. Set the oracle price to be below the strike price
        // 3. Call settleExpiredOption
        // 4. Expect no change in collateral balances from settlement (payout is zero)
        // 5. Expect the seller to be able to withdraw their full collateral
        // 6. Expect the option tokens to be burned
      });
    });

    describe("Liquidation", function () {
      it.skip("should allow a liquidator to liquidate an under-collateralized position", async function () {
        // 1. A seller opens a short position
        // 2. The value of the underlying asset increases dramatically (mocked via oracle)
        // 3. The seller's position is now under-collateralized
        // 4. A liquidator calls liquidatePosition
        // 5. Expect the seller's position to be closed
        // 6. Expect the seller's collateral to be seized
        // 7. Expect the liquidator to receive a portion of the seized collateral as a fee
      });
    });
  });
});
