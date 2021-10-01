    
//:: Created with 💚 by Ignacio Souto 😈 :: Running on Ethereum::
//:: https://www.blocknitive.com ::

//   ██████╗ ██╗      ██████╗  ██████╗██╗  ██╗███╗   ██╗██╗████████╗██╗██╗   ██╗███████╗
//   ██╔══██ ██║     ██╔═══██╗██╔════╝██║ ██╔╝████╗  ██║██║╚══██╔══╝██║██║   ██║██╔════╝
//   ██████╔ ██║     ██║   ██║██║     █████╔╝ ██╔██╗ ██║██║   ██║   ██║██║   ██║█████╗  
//   ██╔══██ ██║     ██║   ██║██║     ██╔═██╗ ██║╚██╗██║██║   ██║   ██║╚██╗ ██╔╝██╔══╝  
//   ██████╔ ███████╗╚██████╔╝╚██████╗██║  ██╗██║ ╚████║██║   ██║   ██║ ╚████╔╝ ███████╗
//    ╚═════╝╚══════╝ ╚═════╝  ╚═════╝╚═╝  ╚═╝╚═╝  ╚═══╝╚═╝   ╚═╝   ╚═╝  ╚═══╝  ╚══════╝
     
//  👽👽👽👽👽👽👽👽👽👽👽👽👽👽👽👽👽👽
//  ██████╗ ██╗   ██╗
//  ██╔══██╗╚██╗ ██╔╝
//  ██████╔╝ ╚████╔╝ 
//  ██╔══██╗  ╚██╔╝  
//  ██████╔╝   ██║   
//  ╚═════╝    ╚═╝
//  👽👽👽👽👽👽👽👽👽👽👽👽👽👽👽👽👽👽

//  ██╗ ██████╗ ███╗   ██╗ █████╗  ██████╗██╗ ██████╗     ███████╗ ██████╗ ██╗   ██╗████████╗ ██████╗ 
//  ██║██╔════╝ ████╗  ██║██╔══██╗██╔════╝██║██╔═══██╗    ██╔════╝██╔═══██╗██║   ██║╚══██╔══╝██╔═══██╗
//  ██║██║  ███╗██╔██╗ ██║███████║██║     ██║██║   ██║    ███████╗██║   ██║██║   ██║   ██║   ██║   ██║
//  ██║██║   ██║██║╚██╗██║██╔══██║██║     ██║██║   ██║    ╚════██║██║   ██║██║   ██║   ██║   ██║   ██║
//  ██║╚██████╔╝██║ ╚████║██║  ██║╚██████╗██║╚██████╔╝    ███████║╚██████╔╝╚██████╔╝   ██║   ╚██████╔╝
//  ╚═╝ ╚═════╝ ╚═╝  ╚═══╝╚═╝  ╚═╝ ╚═════╝╚═╝ ╚═════╝     ╚══════╝ ╚═════╝  ╚═════╝    ╚═╝    ╚═════╝ 
                                                                                                    

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;


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
    /// @dev Accumulated amount of all ETH withdrawn by participants.
    uint256 public withdrawnETH;
    /// @dev Count of the number the project has withdrawn from the funds raised.
    uint256 public projectWithdrawCount;
    /// @dev Total amount of ETH withdrawn by the project
    uint256 public projectWithdrawnETH;

    /// @dev Minimum amount of ETH accepted for a contribution. Everything lower than that will trigger a canceling of pending ETH.
    uint256 public minContribution = 0.01 ether;
    uint256 public maxContribution = 5 ether;

    mapping(uint8 => Stage) public stages;
    uint8 public stageCount;

    /// @dev Maps contributors stats by their address.
    mapping(address => Contributors) public contributors;
    /// @dev Maps contributors address to a unique participant ID (incremental IDs, based on "participantCount").
    mapping(uint256 => address) public contributorsById;
    /// @dev Total number of ICO contributors.
    uint256 public participantCount;

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
     *   Buy phases (Stages PreIco 1)
     */
    /// @dev Block number that indicates the start of the buy phase (Stages 1).
    uint256 public buyPhaseStartBlock;
    /// @dev Block number that indicates the end of the buy phase.
    uint256 public buyPhaseEndBlock;
    /// @dev The duration of the buy phase in blocks.
    uint256 public buyPhaseBlockCount;

    /*
     *   Buy phases (Stages Ico 2)
     */
    /// @dev Block number that indicates the start of the buy phase (Stages 1-n).
    uint256 public buyPhaseStartBlock;
    /// @dev Block number that indicates the end of the buy phase.
    uint256 public buyPhaseEndBlock;
    /// @dev The duration of the buy phase in blocks.
    uint256 public buyPhaseBlockCount;
    
    
    /*
     *   Buy phases (Stages Post-Ico 3)
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
    /// @dev Total amount of the current reserved ETH for the project by the participants contributions.
    uint256 internal _projectCurrentlyReservedETH;
    /// @dev Accumulated amount allocated to the project by participants.
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
        uint256 tokenLimit; // 10000000 >
        uint256 tokenPrice; // 
    }

