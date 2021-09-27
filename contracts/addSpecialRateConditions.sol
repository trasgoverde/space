    function addSpecialRateConditions(address _address, uint256 _rate) public onlyOwner {
        require(_address != address(0));
        require(_rate > 0);

        conditions[_address] = _rate;
        ConditionsAdded(_address, _rate);
    }

    // Returns TUTs rate per 1 ETH depending on current time
    function getRateByTime() public constant returns (uint256) {
        uint256 timeNow = now;
        if (timeNow > (startTime + 11 weeks)) {
            return 50000;
        } else if (timeNow > (startTime + 2 weeks)) {
            return 100000; // - 50%
        } else if (timeNow > (startTime + 4 weeks)) {
            return 75000; // - 25%
        } else {
            return 50000; // +0%
        }
    }