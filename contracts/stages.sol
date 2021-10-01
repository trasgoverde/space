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
                                                                                                    

// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract StateMachine {
    enum Stages {
        PreIcoStage,
        IcoStage,
        PostIcoStage
    }
    /// Function cannot be called at this time.
    error FunctionInvalidAtThisStage;

    // This is the current stage.
    Stages public stage = Stages.PreIcoStage;

    uint public creationTime = block.timestamp;

    modifier atStage(Stages _stage) {
        if (stage == _stage)
            return FunctionValidAtThisStage();
        _;    
    }
    modifier atStage(Stages _stage) {
        if (stage != _stage)
            revert FunctionInvalidAtThisStage();
        _;
    }

    function nextStage() internal {
        stage = Stages(uint(stage) + 1);
    }

    // Perform timed transitions. Be sure to mention
    // this modifier first, otherwise the guards
    // will not take the new stage into account.
    modifier timedTransitions() {
        if (stage == Stages.PreIcoStage &&
                    block.timestamp >= creationTime)
            nextStage();
        if (stage == Stages.IcoStage &&
                block.timestamp >= creationTime + 2 weeks)
            nextStage();
        if (stage == Stages.PostIcoStage &&
                block.timestamp >= creationTime + 4 weeks)
            nextStage();

        // The other stages transition by transaction
        _;
    }
    function setStages (uint256 PreIco, uint256 ico, uint256 PostIco) public onlyOwner {
        if(uint256(Stages.PreIco) == _stage) {
            _stage = Stages.PreIco;
        else if (uint256(Stages.ico)) == _stage {
             _stage = Stages.ico;
        else if (uint256(Stages.PostIco) == _stage {
             _stage = Stages.PostIco;
        }     
        
            }
         if (stage == Stages:preIco) {
             rate = 100000;
         } else if (stage == Stages.ico) {
             rate 75000;
         }  else if (stage == Stages.PostIco) {
             rate = 50000;
         } 
        }

    }

  // Order of the modifiers matters here!
    function buyTokens();()
        public
        payable
        timedTransitions
        atStage(Stages.PreIcoStage)
    {
        // We will not implement that here
    }

    function buyTokens()
        public
        payable
        timedTransitions
        atStage(Stages.IcoStage)
    {
    }

    // This modifier goes to the next stage
    // after the function is done.
    modifier transitionNext()
    {
        _;
        nextStage();
    }

    function buyTokens()
        public
        payable
        timedTransitions
        atStage(Stages.PostIcoStage)
        transitionNext
    {
    }
    function i()
        public
        timedTransitions
        atStage(Stages.Finished)
    {
    }
}
