// SPDX-License-Identifier: MIT
pragma solidity ^0.5.5;

contract Stages{ 
  /**
  * @dev Allows admin to update the crowdsale stage
  * @param _stage Crowdsale stage
  */
  enum CrowdsaleStages {PreICO (uint _stage), ICO (uint _stage),
   PostICO (uint _stage)} public {
    PreICO[0] = _stage;
    ICO[1] = _stage;
    PostICO [2] = _stage;
  }
  CrowdsaleStage public stage =CorwdsaleStage.PreICO;
  function setCrowdsaleStage(uint _stage) public onlyOwner {    
    if(uint(CrowdsaleStage.PreICO) == _stage) {
      stage = CrowdsaleStage.PreICO;
    } else if (uint(CrowdsaleStage.ICO) == _stage) {
      stage = CrowdsaleStage.ICO;
    }

    if(stage == CrowdsaleStage.PreICO) {
      rate = 100000;
    } else if (stage == CrowdsaleStage.ICO) {
      rate = 75000;
    } else if (stage == CrowdsaleStage.PostICO) {
      rate = 50000;
    }
  }

  /**
   * @dev forwards funds to the wallet during the PreICO stage, then the refund vault during ICO stage
   */
  function _forwardFunds() internal {
    if(stage == CrowdsaleStage.PreICO) {
      wallet.transfer(msg.value);
    } else if (stage == CrowdsaleStage.ICO) {
      wallet.transfer(msg.value);
    }  else if (stage == CrowdsaleStage.PostICO) {
      super._forwardFunds();
  }

  /**
  * @dev Extend parent behavior requiring purchase to respect investor min/max funding cap.
  * @param _beneficiary Token purchaser
  * @param _weiAmount Amount of wei contributed
  */
  function _preValidatePurchase(
    address _beneficiary,
    uint256 _weiAmount
  )
    internal
  {
    super._preValidatePurchase(_beneficiary, _weiAmount);
    uint256 _existingContribution = contributions[_beneficiary];
    uint256 _newContribution = _existingContribution.add(_weiAmount);
    require(_newContribution >= investorMinCap && _newContribution <= investorHardCap);
    contributions[_beneficiary] = _newContribution;
  }
  } 