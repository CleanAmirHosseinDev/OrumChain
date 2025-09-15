// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/governance/TimelockController.sol";

/**
 * @title TimelockAndMultisigProxy
 * @author Your Name
 * @notice A proxy contract combining a multi-signature wallet with a timelock for governance.
 * @dev This contract serves as a basic placeholder for a more robust DAO or governance mechanism.
 * The workflow is as follows:
 * 1. A proposal (a target contract, value, and calldata) is created off-chain.
 * 2. Designated signers call `signProposal` to approve it.
 * 3. Once the number of signatures reaches a defined threshold, the proposal is automatically scheduled in an internal `TimelockController`.
 * 4. After the timelock delay has passed, anyone can call `executeProposal` to execute the transaction.
 */
contract TimelockAndMultisigProxy is AccessControl {
    /** @notice The `TimelockController` instance that manages the execution delay of proposals. */
    TimelockController public immutable timelock;
    /** @notice Mapping to identify addresses that are authorized signers. */
    mapping(address => bool) public isSigner;
    /** @notice The number of signatures required to schedule a proposal. */
    uint256 public signatureThreshold;

    /** @notice Mapping from a proposal's hash to the number of signatures it has received. */
    mapping(bytes32 => uint256) public signatureCounts;
    /** @notice Mapping to track which signers have already signed a specific proposal to prevent duplicate votes. */
    mapping(bytes32 => mapping(address => bool)) public hasSigned;

    /** @notice Emitted when a signer successfully signs a proposal. */
    event ProposalSigned(bytes32 indexed proposalHash, address indexed signer);
    /** @notice Emitted when a proposal is successfully executed after its timelock delay. */
    event ProposalExecuted(bytes32 indexed proposalHash);

    /**
     * @notice Initializes the multi-sig and timelock proxy.
     * @param _signers An array of addresses for the initial set of authorized signers.
     * @param _threshold The minimum number of signatures required to schedule a proposal.
     * @param _timelockDelay The delay (in seconds) that must pass between scheduling and executing a proposal.
     */
    constructor(address[] memory _signers, uint256 _threshold, uint256 _timelockDelay) {
        timelock = new TimelockController(
            _timelockDelay,
            // Proposers and executors for the TimelockController are this contract itself,
            // as it's controlled by the multi-sig logic.
            address(this),
            address(this)
        );

        require(_signers.length > 0, "TMProxy: No signers provided");
        require(_threshold > 0 && _threshold <= _signers.length, "TMProxy: Invalid threshold");

        for (uint i = 0; i < _signers.length; i++) {
            isSigner[_signers[i]] = true;
        }
        signatureThreshold = _threshold;
    }

    /**
     * @notice Allows an authorized signer to cast a vote for a proposal.
     * @dev If a signature causes the proposal to meet its threshold, this function will automatically schedule the proposal with the `TimelockController`. A proposal is uniquely identified by the hash of its target, value, data, and a salt.
     * @param target The address of the contract to be called.
     * @param value The amount of ETH to be sent with the call.
     * @param data The calldata of the function to be executed on the target.
     * @param salt A random value (nonce) to ensure proposal uniqueness.
     */
    function signProposal(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 salt
    ) external {
        require(isSigner[msg.sender], "TMProxy: Not a signer");

        bytes32 proposalHash = keccak256(abi.encode(target, value, data, salt));
        require(!hasSigned[proposalHash][msg.sender], "TMProxy: Already signed");

        hasSigned[proposalHash][msg.sender] = true;
        signatureCounts[proposalHash]++;

        emit ProposalSigned(proposalHash, msg.sender);

        if (signatureCounts[proposalHash] >= signatureThreshold) {
            // Schedule the proposal in the timelock.
            // The predecessor is 0, meaning no specific execution order is required relative to other proposals.
            timelock.schedule(target, value, data, 0, salt, timelock.getMinDelay());
        }
    }

    /**
     * @notice Executes a proposal that has passed its timelock delay.
     * @dev Anyone can call this function. The internal call to `timelock.execute` will revert if the proposal is not yet ready for execution (i.e., the delay has not passed).
     * @param target The address of the contract to be called.
     * @param value The amount of ETH to be sent with the call.
     * @param data The calldata of the function to be executed on the target.
     * @param salt The salt used when the proposal was signed.
     */
    function executeProposal(
        address target,
        uint256 value,
        bytes calldata data,
        bytes32 salt
    ) external {
        // The TimelockController will revert if the proposal is not ready for execution.
        timelock.execute(target, value, data, 0, salt);
        emit ProposalExecuted(keccak256(abi.encode(target, value, data, salt)));
    }
}
