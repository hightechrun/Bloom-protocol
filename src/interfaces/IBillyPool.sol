// SPDX-License-Identifier: MIT
/*
██████╗ ██╗     ██╗   ██╗███████╗██████╗ ███████╗██████╗ ██████╗ ██╗   ██╗
██╔══██╗██║     ██║   ██║██╔════╝██╔══██╗██╔════╝██╔══██╗██╔══██╗╚██╗ ██╔╝
██████╔╝██║     ██║   ██║█████╗  ██████╔╝█████╗  ██████╔╝██████╔╝ ╚████╔╝
██╔══██╗██║     ██║   ██║██╔══╝  ██╔══██╗██╔══╝  ██╔══██╗██╔══██╗  ╚██╔╝
██████╔╝███████╗╚██████╔╝███████╗██████╔╝███████╗██║  ██║██║  ██║   ██║
╚═════╝ ╚══════╝ ╚═════╝ ╚══════╝╚═════╝ ╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝
*/

pragma solidity 0.8.19;

import {AssetCommitment} from "../lib/CommitmentsLib.sol";

struct BillyPoolInitParams {
    address underlyingToken;
    address billToken;
    address whitelist;
    address swapFacility;
    uint256 leverageBps;
    uint256 minBorrowDeposit;
    uint256 commitPhaseDuration;
    uint256 poolPhaseDuration;
    uint256 lenderReturnBps;
    string name;
    string symbol;
}

enum State {
    Other,
    Commit,
    ReadyPreHoldSwap,
    PendingPreHoldSwap,
    Holding,
    ReadyPostHoldSwap,
    PendingPostHoldSwap,
    FinalWithdraw
}

/// @author philogy <https://github.com/philogy>
interface IBillyPool {
    // Initialization errors
    error ZeroAddress();
    error NoLenderBorrowerSpread();
    error PhaseTooShort();

    error NotSwapFacility();
    error InvalidOutToken(address outToken);

    error NotWhitelisted();
    error NoCommitToProcess();
    error CommitTooSmall();

    error CanOnlyWithdrawProcessedCommit(uint256 id);
    error NoCommitToWithdraw();

    error InvalidState(State current);

    event BorrowerCommit(address indexed owner, uint256 indexed id, uint256 amount, uint256 cumulativeAmountEnd);
    event LenderCommit(address indexed owner, uint256 indexed id, uint256 amount, uint256 cumulativeAmountEnd);
    event BorrowerCommitmentProcessed(
        address indexed owner, uint256 indexed id, uint256 includedAmount, uint256 excludedAmount
    );
    event LenderCommitmentProcessed(
        address indexed owner, uint256 indexed id, uint256 includedAmount, uint256 excludedAmount
    );
    event ExplictStateTransition(State prevState, State newState);
    event BorrowerWithdraw(address indexed owner, uint256 indexed id, uint256 amount);
    event LenderWithdraw(address indexed owner, uint256 sharesRedeemed, uint256 amount);

    /// @notice Initiates the pre-hold swap.
    function initiatePreHoldSwap() external;

    /// @notice Initiates the post-hold swap.
    function initiatePostHoldSwap() external;

    /**
     * @notice Deposits funds from the borrower committing them for the duration of the commit
     * phase.
     * @param amount The amount of tokens to deposit.
     * @param whitelistProof The whitelist proof data, format dependent on implementation.
     * @return newCommitmentId The commitment ID for the borrower's new deposit.
     */
    function depositBorrower(uint256 amount, bytes calldata whitelistProof)
        external
        returns (uint256 newCommitmentId);
    /**
     * @notice Deposits funds from the lender committing them for the duration of the commit phase.
     * @param amount The amount of stablecoins to deposit.
     * @return newCommitmentId The commitment ID for the lender deposit.
     */
    function depositLender(uint256 amount) external returns (uint256 newCommitmentId);

    /**
     * @notice Processes a borrower's commit, calculates the included and excluded amounts, and refunds any unmatched amounts.
     * @param commitId The borrower's commitment ID.
     */
    function processBorrowerCommit(uint256 commitId) external;

    /**
     * @notice Processes a lender's commit, calculates the included and excluded amounts, mints shares, and refunds any unmatched amounts.
     * @param commitId The lender's commitment ID.
     */
    function processLenderCommit(uint256 commitId) external;

    /**
     * @notice Allows borrowers to withdraw their share of the returned stablecoins after the pool phase has ended and swaps have been completed.
     * @param id The borrower's commitment ID.
     */
    function withdrawBorrower(uint256 id) external;

    /**
     * @notice Allows lenders to withdraw their share of the returned stablecoins and earned interest after the pool phase has ended and swaps have been completed.
     * @param shares The number of lender shares to withdraw.
     */
    function withdrawLender(uint256 shares) external;

    function UNDERLYING_TOKEN() external view returns (address);
    function BILL_TOKEN() external view returns (address);
    function WHITELIST() external view returns (address);
    function SWAP_FACILITY() external view returns (address);
    function LEVERAGE_BPS() external view returns (uint256);
    function MIN_BORROW_DEPOSIT() external view returns (uint256);
    function COMMIT_PHASE_END() external view returns (uint256);
    function POOL_PHASE_END() external view returns (uint256);
    function LENDER_RETURN_BPS() external view returns (uint256);

    function state() external view returns (State currentState);
    function totalMatchAmount() external view returns (uint256);

    function getBorrowCommitment(uint256 id) external view returns (AssetCommitment memory);
    function getLenderCommitment(uint256 id) external view returns (AssetCommitment memory);

    function getTotalBorrowCommitment()
        external
        view
        returns (uint256 totalAssetsCommited, uint256 totalCommitmentCount);
    function getTotalLendCommitment()
        external
        view
        returns (uint256 totalAssetsCommited, uint256 totalCommitmentCount);

    function getDistributionInfo()
        external
        view
        returns (
            uint256 borrowerDistribution,
            uint256 totalBorrowerShares,
            uint256 lenderDistribution,
            uint256 totalLenderShares
        );
}