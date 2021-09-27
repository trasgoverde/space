// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract Stages
    /*
     *   Contract States
     */
    /// @dev It is set to TRUE after the deployer initializes the contract.
    bool public initialized;

    /*
     *   Addresses
     */
    /// @dev Only the deploying address is allowed to initialize the contract.
    address public deployingAddress;
    /// @dev The ICO token contract address.
    address public tokenAddress;
    /// @dev The address of wallet of the project running the ICO.
    address public projectAddress;
    /// @dev Only the whitelist controller can whitelist addresses.
    address public whitelistingAddress;


    /*
     *   Public Variables
     */
    /// @dev Total amount tokens initially available to be bought, increases if the project adds more.
    uint256 public initialTokenSupply;
    /// @dev Total amount tokens currently available to be bought.
    uint256 public tokenSupply;
    /// @dev Total amount of ETH currently accepted as a commitment to buy tokens (excluding pendingETH).
    uint256 public committedETH;
    /// @dev Total amount of ETH currently pending to be whitelisted.
    uint256 public pendingETH;
    /// @dev Accumulated amount of all ETH returned from canceled pending ETH.
    uint256 public canceledETH;
    /// @dev Accumulated amount of all ETH withdrawn by contributors.
    uint256 public withdrawnETH;
    /// @dev Count of the number the project has withdrawn from the funds raised.
    uint256 public projectWithdrawCount;
    /// @dev Total amount of ETH withdrawn by the project
    uint256 public projectWithdrawnETH;

    /// @dev Minimum amount of ETH accepted for a contribution. Everything lower than that will trigger a canceling of pending ETH.
    uint256 public minContribution = 0.02 ether;
    uint256 public maxContribution = 2 ether;

    mapping(uint8 => Stage) public stages;
    uint8 public stageCount;

    /// @dev Maps contributors stats by their address.
    mapping(address => Contributors) public contributors;
    /// @dev Maps contributors address to a unique contributor ID (incremental IDs, based on "contributorCount").
    mapping(uint256 => address) public contributorsById;
    /// @dev Total number of ICO contributors.
    uint256 public contributorCount;

    /*
     *   Commit phase (Stage 0)
     */
    /// @dev Initial token price in the commit phase (Stage 0).
    uint256 public commitPhasePrice;
    /// @dev Block number that indicates the start of the commit phase.
    uint256 public commitPhaseStartBlock;
    /// @dev Block number that indicates the end of the commit phase.
    uint256 public commitPhaseEndBlock;
    /// @dev The duration of the commit phase in blocks.
    uint256 public commitPhaseBlockCount;


    /*
     *   Buy phases (Stages 1-n)
     */
    /// @dev Block number that indicates the start of the buy phase (Stages 1-n).
    uint256 public buyPhaseStartBlock;
    /// @dev Block number that indicates the end of the buy phase.
    uint256 public buyPhaseEndBlock;
    /// @dev The duration of the buy phase in blocks.
    uint256 public buyPhaseBlockCount;

    /*
    *   Internal Variables
    */
    /// @dev Total amount of the current reserved ETH for the project by the contributors contributions.
    uint256 internal _projectCurrentlyReservedETH;
    /// @dev Accumulated amount allocated to the project by contributors.
    uint256 internal _projectUnlockedETH;
    /// @dev Last block since the project has calculated the _projectUnlockedETH.
    uint256 internal _projectLastBlock;


    /*
    *   Structs
    */

    /*
     *   Stages
     *   Stage 0 = commit phase
     *   Stage 1-n = buy phase
     */
    struct Stage {
        uint256 tokenLimit; // 1.000.000 SPACES >
        uint256 tokenPrice;
    }

    /*
     * contributors
     */
    struct contributor {
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
    event PendingContributionAdded(address indexed contributorAddress, uint256 indexed amount, uint32 indexed contributionId, uint8 stageId);
    event PendingContributionsCanceled(address indexed contributorAddress, uint256 indexed amount, uint32 indexed contributionId);

    event WhitelistApproved(address indexed contributorAddress, uint256 indexed pendingETH, uint32 indexed contributions);
    event WhitelistRejected(address indexed contributorAddress, uint256 indexed pendingETH, uint32 indexed contributions);

    event ContributionsAccepted(address indexed contributorAddress, uint256 indexed ethAmount, uint256 indexed tokenAmount, uint8 stageId);

    event ProjectWithdraw(address indexed projectAddress, uint256 indexed amount, uint32 indexed withdrawCount);
    event contributorWithdraw(address indexed contributorAddress, uint256 indexed ethAmount, uint256 indexed tokenAmount, uint32 withdrawCount);

    event StageChanged(uint8 indexed stageId, uint256 indexed tokenLimit, uint256 indexed tokenPrice, uint256 effectiveBlockNumber);
    event WhitelistingAddressChanged(address indexed whitelistingAddress, uint8 indexed stageId, uint256 indexed effectiveBlockNumber);
    event FreezerAddressChanged(address indexed freezerAddress, uint8 indexed stageId, uint256 indexed effectiveBlockNumber);

    event SecurityFreeze(address indexed freezerAddress, uint8 indexed stageId, uint256 indexed effectiveBlockNumber);
    event SecurityUnfreeze(address indexed freezerAddress, uint8 indexed stageId, uint256 indexed effectiveBlockNumber);
    event SecurityDisableEscapeHatch(address indexed freezerAddress, uint8 indexed stageId, uint256 indexed effectiveBlockNumber);
    event SecurityEscapeHatch(address indexed rescuerAddress, address indexed to, uint8 indexed stageId, uint256 effectiveBlockNumber);


    event TransferEvent (
        uint8 indexed typeId,
        address indexed relatedAddress,
        uint256 indexed value
    );

    enum TransferTypes {
        NOT_SET, // 0
        WHITELIST_REJECTED, // 1
        CONTRIBUTION_CANCELED, // 2
        CONTRIBUTION_ACCEPTED_OVERFLOW, // 3 not accepted ETH
        contributor_WITHDRAW, // 4
        contributor_WITHDRAW_OVERFLOW, // 5 not returnable tokens
        PROJECT_WITHDRAWN, // 6
    }


    // ------------------------------------------------------------------------------------------------

    /// @notice Constructor sets the deployer and defines ERC777TokensRecipient interface support.
    constructor() public {
        deployingAddress = msg.sender;
        ERC1820.setInterfaceImplementer(address(this), TOKENS_RECIPIENT_INTERFACE_HASH, address(this));
    }

    /**
     * @notice Initializes the contract. Only the deployer (set in the constructor) can call this method.
     * @param _tokenAddress The address of the ERC777 ICO token contract.
     * @param _whitelistingAddress The address handling whitelisting.
     * @param _projectAddress The project wallet that can withdraw ETH contributions.
     * @param _commitPhaseStartBlock The block at which the commit phase starts.
     * @param _buyPhaseStartBlock The duration of the commit phase in blocks.
     * @param _initialPrice The initial token price (in WEI per token) during the commit phase.
     * @param _stageCount The number of the ICO stages, excluding the commit phase (Stage 0).
     * @param _stageTokenLimitIncrease The duration of each stage in blocks.
     * @param _stagePriceIncrease A factor used to increase the token price from the _initialPrice at each subsequent stage.
     */
    function init(
        address _tokenAddress,
        address _whitelistingAddress,
        address _freezerAddress,
        address _rescuerAddress,
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
    onlyDeployingAddress
    isNotInitialized
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

        // The contract is now initialized
        initialized = true;
    }

    /*
     * Public functions
     * ------------------------------------------------------------------------------------------------
     */

    /*
     * Public functions
     * The main way to interact with the ICO.
     */

    /**
     * @notice FALLBACK function: If the amount sent is smaller than `minContribution` it cancels all pending contributions.
     * IF you are a known contributor with at least 1 contribution and you are whitelisted, you can send ETH without calling "commit()" to contribute more.
     */
    function()
    external
    payable
    isInitialized
    {
        contributor storage contributorStats = contributors[msg.sender];

        // allow to commit directly if its a known user with at least 1 contribution
        if  contributorStats.whitelisted == true && contributorStats.contributions > 0) {
            commit();

        // otherwise try to cancel
        } else {
            require(msg.value < minContribution, 'To contribute call commit() [0x3c7a3aff] and send ETH along.');

            // contributor cancels pending contributions.
            cancelPendingContributions(msg.sender, msg.value);
        }
    }

    /**
     * @notice ERC777TokensRecipient implementation for receiving ERC777 tokens.
     * @param _from Token sender.
     * @param _amount Token amount.
     */
    function tokensReceived(
        address,
        address _from,
        address,
        uint256 _amount,
        bytes calldata,
        bytes calldata
    )
    external
    isInitialized
    {
        // ICO should only receive tokens from the ICO token contract.
        // Transactions from any other token contract revert
        require(msg.sender == tokenAddress, "Unknown token contract sent tokens.");

        // Project wallet adds tokens to the sale
        if (_from == projectAddress) {
            // increase the supply
            tokenSupply = tokenSupply.add(_amount);
            initialTokenSupply = initialTokenSupply.add(_amount);

            // ICO contributor sends tokens back
        } else {
            withdraw(_from, _amount);
        }
    }

    /**
     * @notice Allows a contributor to reserve tokens by committing ETH as contributions.
     *
     *  Function signature: 0x3c7a3aff
     */
    function commit()
    public
    payable
    isInitialized
    isRunning
    {
        // Reject contributions lower than the minimum amount, and max than maxContribution
        require(msg.value >= minContribution, "Value sent is less than the minimum contribution.");

        // contributor initial state record
        uint8 currentStage = getCurrentStage();
        contributor storage contributorStats = contributors[msg.sender];
        contributorstageDetails storage byStage = contributorStats.stages[currentStage];

        require contributorStats.committedETH.add(msg.value) <= maxContribution, "Value sent is larger than the maximum contribution.");

        // Check if contributor already exists
        if  contributorStats.contributions == 0) {
            // Identify the contributors by their Id
        contributorsById[contributorCount] = msg.sender;
            // Increase contributor count
            contributorCount++;
        }

        // UPDATE contributor STATS
    contributorStats.contributions++;
    contributorStats.pendingETH = contributorStats.pendingETH.add(msg.value);
        byStage.pendingETH = byStage.pendingETH.add(msg.value);

        // UPDATE GLOBAL STATS
        pendingETH = pendingETH.add(msg.value);

        emit PendingContributionAdded(
            msg.sender,
            msg.value,
            uint32 contributorStats.contributions),
            currentStage
        );

        // If whitelisted, process the contribution automatically
        if  contributorStats.whitelisted == true) {
            acceptContributions(msg.sender);
        }
    }

    /**
     * @notice Allows a contributor to cancel pending contributions
     *
     *  Function signature: 0xea8a1af0
     */
    function cancel()
    external
    payable
    isInitialized
    {
        cancelPendingContributions(msg.sender, msg.value);
    }

    /**
     * @notice Approves or rejects contributors.
     * @param _addresses The list of contributor address.
     * @param _approve Indicates if the provided contributors are approved (true) or rejected (false).
     */
    function whitelist(address[] calldata _addresses, bool _approve)
    external
    onlyWhitelistingAddress
    isInitialized
    isRunning
    {
        // Revert if the provided list is empty
        require(_addresses.length > 0, "No addresses given to whitelist.");

        for (uint256 i = 0; i < _addresses.length; i++) {
            address contributorAddress = _addresses[i];

            contributor storage contributorStats = contributors[contributorAddress];

            if (_approve) {
                if  contributorStats.whitelisted == false) {
                    // If contributors are approved: whitelist them and accept their contributions
                contributorStats.whitelisted = true;
                    emit WhitelistApproved(contributorAddress, contributorStats.pendingETH, uint32 contributorStats.contributions));
                }

                // accept any pending ETH
                acceptContributions(contributorAddress);

            } else {
            contributorStats.whitelisted = false;
                emit WhitelistRejected(contributorAddress, contributorStats.pendingETH, uint32 contributorStats.contributions));

                // Cancel contributors pending contributions.
                cancelPendingContributions(contributorAddress, 0);
            }
        }
    }

    /**
     * @notice Allows the project to withdraw tokens.
     * @param _tokenAmount The token amount.
     */
    function projectTokenWithdraw(uint256 _tokenAmount)
    external
    onlyProjectAddress
    isInitialized
    {
        require(_tokenAmount <= tokenSupply, "Requested amount too high, not enough tokens available.");

        // decrease the supply
        tokenSupply = tokenSupply.sub(_tokenAmount);
        initialTokenSupply = initialTokenSupply.sub(_tokenAmount);

        // sent all tokens from the contract to the _to address
        // solium-disable-next-line security/no-send
        IERC20(tokenAddress).transfer(projectAddress, _tokenAmount);
    }

    /**
     * @notice Allows for the project to withdraw ETH.
     * @param _ethAmount The ETH amount in wei.
     */
    function projectWithdraw(uint256 _ethAmount)
    external
    onlyProjectAddress
    isInitialized
    {
        // UPDATE the locked/unlocked ratio for the project
        calcProjectAllocation();

        // Get current allocated ETH to the project
        uint256 availableForWithdraw = _projectUnlockedETH.sub(projectWithdrawnETH);

        require(_ethAmount <= availableForWithdraw, "Requested amount too high, not enough ETH unlocked.");

        // UPDATE global STATS
        projectWithdrawCount++;
        projectWithdrawnETH = projectWithdrawnETH.add(_ethAmount);

        // Event emission
        emit ProjectWithdraw(
            projectAddress,
            _ethAmount,
            uint32(projectWithdrawCount)
        );
        emit TransferEvent(
            uint8(TransferTypes.PROJECT_WITHDRAWN),
            projectAddress,
            _ethAmount
        );

        // Transfer ETH to project wallet
        address(uint160(projectAddress)).transfer(_ethAmount);
    }


    function changeStage(uint8 _stageId, uint256 _tokenLimit, uint256 _tokenPrice)
    external
    onlyProjectAddress
    isInitialized
    {
        stages[_stageId].tokenLimit = _tokenLimit;
        stages[_stageId].tokenPrice = _tokenPrice;

        if(_stageId > stageCount) {
            stageCount = _stageId;
        }

        emit StageChanged(_stageId, _tokenLimit, _tokenPrice, getCurrentEffectiveBlockNumber());
    }


    function changeWhitelistingAddress(address _newAddress)
    external
    onlyProjectAddress
    isInitialized
    {
        whitelistingAddress = _newAddress;
        emit WhitelistingAddressChanged(whitelistingAddress, getCurrentStage(), getCurrentEffectiveBlockNumber());
    }

 

    /*
     * Public view functions
     * ------------------------------------------------------------------------------------------------
     */

    /**
     * @notice Returns project's total unlocked ETH.
     * @return uint256 The amount of ETH unlocked over the whole ICO.
     */
    function getUnlockedProjectETH() public view returns (uint256) {

        // calc from the last known point on
        uint256 newlyUnlockedEth = calcUnlockedAmount(_projectCurrentlyReservedETH, _projectLastBlock);

        return _projectUnlockedETH
        .add(newlyUnlockedEth);
    }

    /**
     * @notice Returns project's current available unlocked ETH reduced by what was already withdrawn.
     * @return uint256 The amount of ETH available to the project for withdraw.
     */
    function getAvailableProjectETH() public view returns (uint256) {
        return getUnlockedProjectETH()
            .sub(projectWithdrawnETH);
    }

    /**
     * @notice Returns the contributor's amount of locked tokens at the current block.
     * @param _contributorAddress The contributor's address.
     */
    function getcontributorReservedTokens(address _contributorAddress) public view returns (uint256) {
        contributor storage contributorStats = contributors[_contributorAddress];

        if contributorStats._currentReservedTokens == 0) {
            return 0;
        }

        return contributorStats._currentReservedTokens.sub(
            calcUnlockedAmount contributorStats._currentReservedTokens, contributorStats._lastBlock)
        );
    }

    /**
     * @notice Returns the contributor's amount of unlocked tokens at the current block.
     * This function is used for internal sanity checks.
     * Note: this value can differ from the actual unlocked token balance of the contributor, if he received tokens from other sources than the ICO.
     * @param _contributorAddress The contributor's address.
     */
    function getcontributorUnlockedTokens(address _contributorAddress) public view returns (uint256) {
        contributor storage contributorStats = contributors[_contributorAddress];

        return contributorStats._unlockedTokens.add(
            calcUnlockedAmount contributorStats._currentReservedTokens, contributorStats._lastBlock)
        );
    }

    /**
    * @notice Returns the token amount that are still available at the current stage
    * @return The amount of tokens
    */
    function getAvailableTokenAtCurrentStage() public view returns (uint256) {
        return stages[getCurrentStage()].tokenLimit.sub(
            initialTokenSupply.sub(tokenSupply)
        );
    }


    /**
     * @notice Returns the current stage at current sold token amount
     * @return The current stage ID
     */
    function getCurrentStage() public view returns (uint8) {
        return getStageByTokenLimit(
            initialTokenSupply.sub(tokenSupply)
        );
    }

    /**
     * @notice Returns the current token price at the current stage.
     * @return The current ETH price in wei.
     */
    function getCurrentPrice() public view returns (uint256) {
        return getPriceAtStage(getCurrentStage());
    }


    /**
     * @notice Returns the token price at the specified stage ID.
     * @param _stageId the stage ID at which we want to retrieve the token price.
     */
    function getPriceAtStage(uint8 _stageId) public view returns (uint256) {
        if (_stageId <= stageCount) {
            return stages[_stageId].tokenPrice;
        }
        return stages[stageCount].tokenPrice;
    }


    /**
     * @notice Returns the token price for when a specific amount of tokens is sold
     * @param _tokenLimit  The amount of tokens for which we want to know the respective token price
     * @return The ETH price in wei
     */
    function getPriceForTokenLimit(uint256 _tokenLimit) public view returns (uint256) {
        return getPriceAtStage(getStageByTokenLimit(_tokenLimit));
    }

    /**
    * @notice Returns the stage at a point where a certain amount of tokens is sold
    * @param _tokenLimit The amount of tokens for which we want to know the stage ID
    */
    function getStageByTokenLimit(uint256 _tokenLimit) public view returns (uint8) {

        // Go through all stages, until we find the one that matches the supply
        for (uint8 stageId = 0; stageId <= stageCount; stageId++) {
            if(_tokenLimit <= stages[stageId].tokenLimit) {
                return stageId;
            }
        }
        // if amount is more than available stages return last stage with the highest price
        return stageCount;
    }

    /**
     * @notice Returns the ICOs available ETH to reserve tokens at a given stage.
     * @param _stageId the stage ID.
     */
    function committableEthAtStage(uint8 _stageId, uint8 _currentStage) public view returns (uint256) {
        uint256 supply;

        // past stages
        if(_stageId < _currentStage) {
            return 0;

        // last stage
        } else if(_stageId >= stageCount) {
            supply = tokenSupply;

        // current stage
        } else if(_stageId == _currentStage) {
            supply = stages[_currentStage].tokenLimit.sub(
                initialTokenSupply.sub(tokenSupply)
            );

        // later stages
        } else if(_stageId > _currentStage) {
            supply = stages[_stageId].tokenLimit.sub(stages[_stageId - 1].tokenLimit); // calc difference to last stage
        }

        return getEthAmountForTokensAtStage(
            supply
        , _stageId);
    }

    /**
     * @notice Returns the amount of ETH (in wei) for a given token amount at a given stage.
     * @param _tokenAmount The amount of token.
     * @param _stageId the stage ID.
     * @return The ETH amount in wei
     */
    function getEthAmountForTokensAtStage(uint256 _tokenAmount, uint8 _stageId) public view returns (uint256) {
        return _tokenAmount
        .mul(stages[_stageId].tokenPrice)
        .div(10 ** 18);
    }

    /**
     * @notice Returns the amount of tokens that given ETH would buy at a given stage.
     * @param _ethAmount The ETH amount in wei.
     * @param _stageId the stage ID.
     * @return The token amount in its smallest unit (token "wei")
     */
    function getTokenAmountForEthAtStage(uint256 _ethAmount, uint8 _stageId) public view returns (uint256) {
        return _ethAmount
        .mul(10 ** 18)
        .div(stages[_stageId].tokenPrice);
    }

    /**
     * @notice Returns the current block number: required in order to override when running tests.
     */
    function getCurrentBlockNumber() public view returns (uint256) {
        return uint256(block.number);
    }

    /**
     * @notice ICO HEART: Calculates the unlocked amount tokens/ETH beginning from the buy phase start or last block to the current block.
     * This function is used by the contributors as well as the project, to calculate the current unlocked amount.
     *
     * @return the unlocked amount of tokens or ETH.
     */
    function calcUnlockedAmount(uint256 _amount, uint256 _lastBlock) public view returns (uint256) {

        uint256 currentBlock = getCurrentEffectiveBlockNumber();

        if(_amount == 0) {
            return 0;
        }

        // Calculate WITHIN the buy phase
        if (currentBlock >= buyPhaseStartBlock && currentBlock < buyPhaseEndBlock) {

            // security/no-assign-params: "calcUnlockedAmount": Avoid assigning to function parameters.
            uint256 lastBlock = _lastBlock;
            if(lastBlock < buyPhaseStartBlock) {
                lastBlock = buyPhaseStartBlock.sub(1); // We need to reduce it by 1, as the startBlock is always already IN the period.
            }

            // get the number of blocks that have "elapsed" since the last block
            uint256 passedBlocks = currentBlock.sub(lastBlock);

            // number of blocks ( ie: start=4/end=10 => 10 - 4 => 6 )
            uint256 totalBlockCount = buyPhaseEndBlock.sub(lastBlock);

            return _amount.mul(
                passedBlocks.mul(10 ** 20)
                .div(totalBlockCount)
            ).div(10 ** 20);

            // Return everything AFTER the buy phase
        } else if (currentBlock >= buyPhaseEndBlock) {
            return _amount;
        }
        // Return nothing BEFORE the buy phase
        return 0;
    }

    /*
     * Internal functions
     * ------------------------------------------------------------------------------------------------
     */


    /**
    * @notice Checks the projects core variables and ETH amounts in the contract for correctness.
    */
    function sanityCheckProject() internal view {
        // PROJECT: The sum of reserved + unlocked has to be equal the committedETH.
        require(
            committedETH == _projectCurrentlyReservedETH.add(_projectUnlockedETH),
            'Project Sanity check failed! Reserved + Unlock must equal committedETH'
        );

        // PROJECT: The ETH in the ICO has to be the total of unlocked + reserved - withdraw
        require(
            address(this).balance == _projectUnlockedETH.add(_projectCurrentlyReservedETH).add(pendingETH).sub(projectWithdrawnETH),
            'Project sanity check failed! balance = Unlock + Reserved - Withdrawn'
        );
    }

    /**
    * @notice Checks the projects core variables and ETH amounts in the contract for correctness.
    */
    function sanityCheckcontributor(address _contributorAddress) internal view {
        contributor storage contributorStats = contributors[_contributorAddress];

        // contributor: The sum of reserved + unlocked has to be equal the totalReserved.
        require(
        contributorStats.reservedTokens == contributorStats._currentReservedTokens.add contributorStats._unlockedTokens),
            'contributor Sanity check failed! Reser. + Unlock must equal totalReser'
        );
    }

    /**
     * @notice Calculates the projects allocation since the last calculation.
     */
    function calcProjectAllocation() internal {

        uint256 newlyUnlockedEth = calcUnlockedAmount(_projectCurrentlyReservedETH, _projectLastBlock);

        // UPDATE GLOBAL STATS
        _projectCurrentlyReservedETH = _projectCurrentlyReservedETH.sub(newlyUnlockedEth);
        _projectUnlockedETH = _projectUnlockedETH.add(newlyUnlockedEth);
        _projectLastBlock = getCurrentEffectiveBlockNumber();

        sanityCheckProject();
    }

    /**
     * @notice Calculates the contributors allocation since the last calculation.
     */
    function calccontributorAllocation(address _contributorAddress) internal {
        contributor storage contributorStats = contributors[_contributorAddress];

        // UPDATE the locked/unlocked ratio for this contributor
    contributorStats._unlockedTokens = getcontributorUnlockedTokens(_contributorAddress);
    contributorStats._currentReservedTokens = getcontributorReservedTokens(_contributorAddress);

        // RESET BLOCK NUMBER: Force the unlock calculations to start from this point in time.
    contributorStats._lastBlock = getCurrentEffectiveBlockNumber();

        // UPDATE the locked/unlocked ratio for the project as well
        calcProjectAllocation();
    }

    /**
     * @notice Cancels any contributor's pending ETH contributions.
     * Pending is any ETH from contributors that are not whitelisted yet.
     */
    function cancelPendingContributions(address _contributorAddress, uint256 _sentValue)
    internal
    isInitialized
    {
        contributor storage contributorStats = contributors[_contributorAddress];
        uint256 contributorPendingEth = contributorStats.pendingETH;

        // Fail silently if no ETH are pending
        if(contributorPendingEth == 0) {
            // sent at least back what he contributed
            if(_sentValue > 0) {
                address(uint160(_contributorAddress)).transfer(_sentValue);
            }
            return;
        }

        // UPDATE contributor STAGES
        for (uint8 stageId = 0; stageId <= stageCount; stageId++) {
        contributorStats.stages[stageId].pendingETH = 0;
        }

        // UPDATE contributor STATS
    contributorStats.pendingETH = 0;

        // UPDATE GLOBAL STATS
        canceledETH = canceledETH.add(contributorPendingEth);
        pendingETH = pendingETH.sub(contributorPendingEth);

        // Emit events
        emit PendingContributionsCanceled(_contributorAddress, contributorPendingEth, uint32 contributorStats.contributions));
        emit TransferEvent(
            uint8(TransferTypes.CONTRIBUTION_CANCELED),
            _contributorAddress,
            contributorPendingEth
        );


        // transfer ETH back to contributor including received value
        address(uint160(_contributorAddress)).transfer(contributorPendingEth.add(_sentValue));

        // SANITY check
        sanityCheckcontributor(_contributorAddress);
        sanityCheckProject();
    }


    /**
    * @notice Accept a contributor's contribution.
    * @param _contributorAddress contributor's address.
    */
    function acceptContributions(address _contributorAddress)
    internal
    isInitialized
    isRunning
    {
        contributor storage contributorStats = contributors[_contributorAddress];

        // Fail silently if no ETH are pending
        if  contributorStats.pendingETH == 0) {
            return;
        }

        uint8 currentStage = getCurrentStage();
        uint256 totalRefundedETH;
        uint256 totalNewReservedTokens;

        calccontributorAllocation(_contributorAddress);

        // set the first contribution block
        if contributorStats.committedETH == 0) {
        contributorStats.firstContributionBlock = contributorStats._lastBlock; // `_lastBlock` was set in calccontributorAllocation()
        }

        // Iterate over all stages and their pending contributions
        for (uint8 stageId = 0; stageId <= stageCount; stageId++) {
        contributorstageDetails storage byStage = contributorStats.stages[stageId];

            // skip if not ETH is pending
            if (byStage.pendingETH == 0) {
                continue;
            }

            // skip if stage is below "currentStage" (as they have no available tokens)
            if(stageId < currentStage) {
                // add this stage pendingETH to the "currentStage"
            contributorStats.stages[currentStage].pendingETH = contributorStats.stages[currentStage].pendingETH.add(byStage.pendingETH);
                // and reset this stage
                byStage.pendingETH = 0;
                continue;
            }

            // --> We continue only if in "currentStage" or later stages

            uint256 maxCommittableEth = committableEthAtStage(stageId, currentStage);
            uint256 newlyCommittableEth = byStage.pendingETH;
            uint256 returnEth = 0;
            uint256 overflowEth = 0;

            // If incoming value is higher than what we can accept,
            // just accept the difference and return the rest
            if (newlyCommittableEth > maxCommittableEth) {
                overflowEth = newlyCommittableEth.sub(maxCommittableEth);
                newlyCommittableEth = maxCommittableEth;

                // if in the last stage, return ETH
                if (stageId == stageCount) {
                    returnEth = overflowEth;
                    totalRefundedETH = totalRefundedETH.add(returnEth);

                // if below the last stage, move pending ETH to the next stage
                } else {
                contributorStats.stages[stageId + 1].pendingETH = contributorStats.stages[stageId + 1].pendingETH.add(overflowEth);
                    byStage.pendingETH = byStage.pendingETH.sub(overflowEth);
                }
            }

            // convert ETH to TOKENS
            uint256 newTokenAmount = getTokenAmountForEthAtStage(
                newlyCommittableEth, stageId
            );

            totalNewReservedTokens = totalNewReservedTokens.add(newTokenAmount);

            // UPDATE contributor STATS
        contributorStats._currentReservedTokens = contributorStats._currentReservedTokens.add(newTokenAmount);
        contributorStats.reservedTokens = contributorStats.reservedTokens.add(newTokenAmount);
        contributorStats.committedETH = contributorStats.committedETH.add(newlyCommittableEth);
        contributorStats.pendingETH = contributorStats.pendingETH.sub(newlyCommittableEth).sub(returnEth);

            byStage.pendingETH = byStage.pendingETH.sub(newlyCommittableEth).sub(returnEth);

            // UPDATE GLOBAL STATS
            tokenSupply = tokenSupply.sub(newTokenAmount);
            pendingETH = pendingETH.sub(newlyCommittableEth).sub(returnEth);
            committedETH = committedETH.add(newlyCommittableEth);
            _projectCurrentlyReservedETH = _projectCurrentlyReservedETH.add(newlyCommittableEth);

            // Emit event
            emit ContributionsAccepted(_contributorAddress, newlyCommittableEth, newTokenAmount, stageId);
        }

        // Refund what couldn't be accepted
        if (totalRefundedETH > 0) {
            emit TransferEvent(uint8(TransferTypes.CONTRIBUTION_ACCEPTED_OVERFLOW), _contributorAddress, totalRefundedETH);
            address(uint160(_contributorAddress)).transfer(totalRefundedETH);
        }

        // Transfer tokens to the contributor
        // solium-disable-next-line security/no-send
        IERC20(tokenAddress).transfer(_contributorAddress, totalNewReservedTokens);

        // SANITY CHECK
        sanityCheckcontributor(_contributorAddress);
        sanityCheckProject();
    }


    /**
     * @notice Allow a contributor to withdraw by sending tokens back to ICO contract.
     * @param _contributorAddress contributor address.
     * @param _returnedTokenAmount The amount of tokens returned.
     */
    function withdraw(address _contributorAddress, uint256 _returnedTokenAmount)
    internal
    isInitialized
    isRunning
    {
        contributor storage contributorStats = contributors[_contributorAddress];

        calccontributorAllocation(_contributorAddress);

        require(_returnedTokenAmount > 0, 'You can not withdraw without sending tokens.');
        require contributorStats._currentReservedTokens > 0 && contributorStats.reservedTokens > 0, 'You can not withdraw, you have no locked tokens.');

        uint256 returnedTokenAmount = _returnedTokenAmount;
        uint256 overflowingTokenAmount;
        uint256 returnEthAmount;

        // Only allow reserved tokens be returned, return the overflow.
        if (returnedTokenAmount > contributorStats._currentReservedTokens) {
            overflowingTokenAmount = returnedTokenAmount.sub contributorStats._currentReservedTokens);
            returnedTokenAmount = contributorStats._currentReservedTokens;
        }

        // Calculate the return amount
        returnEthAmount = contributorStats.committedETH.mul(
            returnedTokenAmount.sub(1).mul(10 ** 20) // deduct 1 token-wei to minimize rounding issues
            .div contributorStats.reservedTokens)
        ).div(10 ** 20);


        // UPDATE contributor STATS
    contributorStats.withdraws++;
    contributorStats._currentReservedTokens = contributorStats._currentReservedTokens.sub(returnedTokenAmount);
    contributorStats.reservedTokens = contributorStats.reservedTokens.sub(returnedTokenAmount);
    contributorStats.committedETH = contributorStats.committedETH.sub(returnEthAmount);

        // UPDATE global STATS
        tokenSupply = tokenSupply.add(returnedTokenAmount);
        withdrawnETH = withdrawnETH.add(returnEthAmount);
        committedETH = committedETH.sub(returnEthAmount);

        _projectCurrentlyReservedETH = _projectCurrentlyReservedETH.sub(returnEthAmount);


        // Return overflowing tokens received
        if (overflowingTokenAmount > 0) {

            // Emit event
            emit TransferEvent(uint8(TransferTypes.contributor_WITHDRAW_OVERFLOW), _contributorAddress, overflowingTokenAmount);

            // send tokens back to contributor
            // solium-disable-next-line security/no-send
            IERC20(tokenAddress).transfer(_contributorAddress, overflowingTokenAmount);
        }

        // Emit events
        emit contributorWithdraw(_contributorAddress, returnEthAmount, returnedTokenAmount, uint32 contributorStats.withdraws));
        emit TransferEvent(uint8(TransferTypes.contributor_WITHDRAW), _contributorAddress, returnEthAmount);

        // Return ETH back to contributor
        address(uint160(_contributorAddress)).transfer(returnEthAmount);

        // SANITY CHECK
        sanityCheckcontributor(_contributorAddress);
        sanityCheckProject();
    }

    /*
     *   Modifiers
     */

    /**
     * @notice Checks if the sender is the project.
     */
    modifier onlyProjectAddress() {
        require(msg.sender == projectAddress, "Only the project can call this method.");
        _;
    }

    /**
     * @notice Checks if the sender is the deployer.
     */
    modifier onlyDeployingAddress() {
        require(msg.sender == deployingAddress, "Only the deployer can call this method.");
        _;
    }

    /**
     * @notice Checks if the sender is the whitelist controller.
     */
    modifier onlyWhitelistingAddress() {
        require(msg.sender == whitelistingAddress, "Only the whitelist controller can call this method.");
        _;
    }

    /**
     * @notice Checks if the sender is the freezer controller address.
     */
    modifier onlyFreezerAddress() {
        require(msg.sender == freezerAddress, "Only the freezer address can call this method.");
        _;
    }

    /**
     * @notice Checks if the sender is the freezer controller address.
     */
    modifier onlyRescuerAddress() {
        require(msg.sender == rescuerAddress, "Only the rescuer address can call this method.");
        _;
    }

    /**
     * @notice Requires the contract to have been initialized.
     */
    modifier isInitialized() {
        require(initialized == true, "Contract must be initialized.");
        _;
    }

    /**
     * @notice Requires the contract to NOT have been initialized,
     */
    modifier isNotInitialized() {
        require(initialized == false, "Contract can not be initialized.");
        _;
    }

    /**
     * @notice @dev Requires the contract to be frozen.
     */
    modifier isFrozen() {
        require(frozen == true, "ICO has to be frozen!");
        _;
    }

    /**
     * @notice @dev Requires the contract not to be frozen.
     */
    modifier isNotFrozen() {
        require(frozen == false, "ICO is frozen!");
        _;
    }

    /**
     * @notice Checks if the ICO is running.
     */
    modifier isRunning() {
        uint256 blockNumber = getCurrentEffectiveBlockNumber();
        require(blockNumber >= commitPhaseStartBlock && blockNumber <= buyPhaseEndBlock, "Current block is outside the ICO period.");
        _;
    }
}