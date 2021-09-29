// SPDX-License-Identifier: MIT
pragma solidity ^0.8.4;
    /*
     *   Contract States
     */

contract Stages {
    /*
     *   Addresses
     */
    /// @dev Only the deploying address is allowed to initialize the contract.
    address deployingAddress;
    /// @dev The rICO token contract address.
    address tokenAddress;
    /// @dev The address of wallet of the project running the rICO.
    address projectAddress;
    /// @dev Only the whitelist controller can whitelist addresses.
    address whitelistingAddress;

    /*
     *   Public Variables
     */
    /// @dev Total amount tokens initially available to be bought, increases if the project adds more.
    uint256 initialTokenSupply;
    /// @dev Total amount tokens currently available to be bought.
    uint256 tokenSupply;
    /// @dev Total amount of ETH currently accepted as a commitment to buy tokens (excluding pendingETH).
    uint256 committedETH;
    /// @dev Total amount of ETH currently pending to be whitelisted.
    uint256 pendingETH;
    /// @dev Accumulated amount of all ETH returned from canceled pending ETH.
    uint256 canceledETH;
    /// @dev Accumulated amount of all ETH withdrawn by contributors.
    uint256 withdrawnETH;
    /// @dev Count of the number the project has withdrawn from the funds raised.
    uint256 projectWithdrawCount;
    /// @dev Total amount of ETH withdrawn by the project
    uint256 projectWithdrawnETH;

    /// @dev Minimum amount of ETH accepted for a contribution. Everything lower than that will trigger a canceling of pending ETH.
    uint256  minContribution = 0.001 ether;
    uint256 maxContribution = 4 ether;

    mapping(uint8 => Stage) stages;
    uint8 stageCount;

    /// @dev Maps contributors stats by their address.
    mapping(address => Contributor) contributors;
    /// @dev Maps contributors address to a unique participant ID (incremental IDs, based on "participantCount").
    mapping(uint256 => address) contributorsById;
    /// @dev Total number of rICO contributors.
    uint256 contributorCount;

    /*
     *   Commit phase (Stage 0)
     */
    /// @dev Initial token price in the commit phase (Stage 0).
    uint256 commitPhasePrice;
    /// @dev Block number that indicates the start of the commit phase.
    uint256 commitPhaseStartBlock;
    /// @dev Block number that indicates the end of the commit phase.
    uint256 commitPhaseEndBlock;
    /// @dev The duration of the commit phase in blocks.
    uint256 commitPhaseBlockCount;


    /*
     *   Buy phases (Stages 1-n)
     */
    /// @dev Block number that indicates the start of the buy phase (Stages 1-n).
    uint256 buyPhaseStartBlock;
    /// @dev Block number that indicates the end of the buy phase.
    uint256 buyPhaseEndBlock;
    /// @dev The duration of the buy phase in blocks.
    uint256 buyPhaseBlockCount;

    /*
    *   Internal Variables
    */
    /// @dev Total amount of the current reserved ETH for the project by the contributors contributions.
    uint256 _projectCurrentlyReservedETH;
    /// @dev Accumulated amount allocated to the project by contributors.
    uint256 _projectUnlockedETH;
    /// @dev Last block since the project has calculated the _projectUnlockedETH.
    uint256 _projectLastBlock;


    /*
    *   Structs
    */

    /*
     *   Stages
     *   Stage 0 = commit phase
     *   Stage 1-n = buy phase
     */
    struct Stage {
        uint256 tokenLimit; 
        uint256 tokenPrice;
    }

    /*
     * contributors
     */
    struct Contributor {
        bool whitelisted;
        uint32 contributions;
        uint32 withdraws;
        uint256 firstContributionBlock;
        uint256 reservedTokens;
        uint256 committedETH;
        uint256 pendingETH;

        uint256 _currentReservedTokens;
        uint256 _unlockedTokens;
        uint256 _lastBlock;

        mapping(uint8 => contributorstageDetails) stages;
    }

    struct contributorstageDetails {
        uint256 pendingETH;
    }

    /*
     * Events
     */
  //  event PendingContributionAdded(address indexed participantAddress, uint256 indexed amount, uint32 indexed contributionId, uint8 stageId);
   //  event PendingContributionsCanceled(address indexed participantAddress, uint256 indexed amount, uint32 indexed contributionId);

   //  event WhitelistApproved(address indexed participantAddress, uint256 indexed pendingETH, uint32 indexed contributions);
  //   event WhitelistRejected(address indexed participantAddress, uint256 indexed pendingETH, uint32 indexed contributions);

  //   event ContributionsAccepted(address indexed participantAddress, uint256 indexed ethAmount, uint256 indexed tokenAmount, uint8 stageId);

  //   event ProjectWithdraw(address indexed projectAddress, uint256 indexed amount, uint32 indexed withdrawCount);
  //    event ParticipantWithdraw(address indexed participantAddress, uint256 indexed ethAmount, uint256 indexed tokenAmount, uint32 withdrawCount);

   //  event StageChanged(uint8 indexed stageId, uint256 indexed tokenLimit, uint256 indexed tokenPrice, uint256 effectiveBlockNumber);
   //  event WhitelistingAddressChanged(address indexed whitelistingAddress, uint8 indexed stageId, uint256 indexed effectiveBlockNumber);
    


   //  event TransferEvent (
 //       uint8 indexed typeId,
   //      address indexed relatedAddress,
   //      uint256 indexed value
  //   );

    enum TransferTypes {
        NOT_SET, // 0
        WHITELIST_REJECTED, // 1
        CONTRIBUTION_CANCELED, // 2
        CONTRIBUTION_ACCEPTED_OVERFLOW, // 3 not accepted ETH
        PARTICIPANT_WITHDRAW, // 4
        PARTICIPANT_WITHDRAW_OVERFLOW, // 5 not returnable tokens
        PROJECT_WITHDRAWN, // 6
        FROZEN_ESCAPEHATCH_TOKEN, // 7
        FROZEN_ESCAPEHATCH_ETH // 8
    }


    // ------------------------------------------------------------------------------------------------

    /// @notice Constructor sets the deployer and defines ERC20TokensRecipient interface support.
    constructor() public {
        deployingAddress = msg.sender;
    
    }

    /**
     * @notice Initializes the contract. Only the deployer (set in the constructor) can call this method.
     * @param _tokenAddress The address of the ERC777 rICO token contract.
     * @param _whitelistingAddress The address handling whitelisting.
     * @param _projectAddress The project wallet that can withdraw ETH contributions.
     * @param _commitPhaseStartBlock The block at which the commit phase starts.
     * @param _buyPhaseStartBlock The duration of the commit phase in blocks.
     * @param _initialPrice The initial token price (in WEI per token) during the commit phase.
     * @param _stageCount The number of the rICO stages, excluding the commit phase (Stage 0).
     * @param _stageTokenLimitIncrease The duration of each stage in blocks.
     * @param _stagePriceIncrease A factor used to increase the token price from the _initialPrice at each subsequent stage.
     */
    function init(
        address _tokenAddress,
        address _whitelistingAddress,
        address _projectAddress,
        uint256 _commitPhaseStartBlock,
        uint256 _buyPhaseStartBlock,
        uint256 _buyPhaseEndBlock,
        uint256 _initialPrice,
        uint8 _stageCount, // Its not recommended to choose more than 50 stages! (9 stages require ~650k GAS when whitelisting contributions, the whitelisting function could run out of gas with a high number of stages, preventing accepting contributions)
        uint256 _stageTokenLimitIncrease,
        uint256 _stagePriceIncrease
    )
    public

    {
        require(_tokenAddress != address(0), "_tokenAddress cannot be 0x");
        require(_whitelistingAddress != address(0), "_whitelistingAddress cannot be 0x");
        require(_projectAddress != address(0), "_projectAddress cannot be 0x");
        // require(_commitPhaseStartBlock > getCurrentBlockNumber(), "Start block cannot be set in the past.");

        // Assign address variables
        tokenAddress = _tokenAddress;
        whitelistingAddress = _whitelistingAddress;
        projectAddress = _projectAddress;

        // UPDATE global STATS
        commitPhaseStartBlock = _commitPhaseStartBlock;
        commitPhaseEndBlock = _buyPhaseStartBlock.sub(1);
        commitPhaseBlockCount = commitPhaseEndBlock.sub(commitPhaseStartBlock).add(1);
        commitPhasePrice = _initialPrice;

        stageCount = _stageCount;


        // Setup stage 0: The commit phase.
        Stage storage commitPhase = stages[0];
        commitPhase.tokenLimit = _stageTokenLimitIncrease;
        commitPhase.tokenPrice = _initialPrice;


        // Setup stage 1 to n: The buy phase stages
        uint256 previousStageTokenLimit = _stageTokenLimitIncrease;

        // Update stages: start, end, price
        for (uint8 i = 1; i <= _stageCount; i++) {
            // Get i-th stage
            Stage storage byStage = stages[i];
            // set the stage limit amount
            byStage.tokenLimit = previousStageTokenLimit.add(_stageTokenLimitIncrease);
            // Store the current stage endBlock in order to update the next one
            previousStageTokenLimit = byStage.tokenLimit;
            // At each stage the token price increases by _stagePriceIncrease * stageCount
            byStage.tokenPrice = _initialPrice.add(_stagePriceIncrease.mul(i));
        }

        // UPDATE global STATS
        // The buy phase starts on the subsequent block of the commitPhase's (stage0) endBlock
        buyPhaseStartBlock = _buyPhaseStartBlock;
        // The buy phase ends when the lat stage ends
        buyPhaseEndBlock = _buyPhaseEndBlock;
        // The duration of buyPhase in blocks
        buyPhaseBlockCount = buyPhaseEndBlock.sub(buyPhaseStartBlock).add(1);

  
    }
}