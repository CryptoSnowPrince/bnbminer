//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract BNBMiner {
    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    uint256 public EGGS_TO_HATCH_1MINERS = 2592000; //for final version should be seconds in a day
    uint256 PSN = 10000;
    uint256 PSNH = 5000;
    bool public initialized = false;
    address public treasury1;
    address public treasury2;
    mapping(address => uint256) public hatcheryMiners;
    mapping(address => uint256) public claimedEggs;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;
    uint256 public marketEggs;

    constructor(address _treasury1, address _treasury2) {
        treasury1 = _treasury1;
        treasury2 = _treasury2;
    }

    function hatchEggs(address ref) public {
        require(initialized, "Not initialized");
        if (ref == msg.sender) {
            ref = 0;
        }
        if (referrals[msg.sender] == 0 && referrals[msg.sender] != msg.sender) {
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs();
        uint256 newMiners = eggsUsed / EGGS_TO_HATCH_1MINERS;
        hatcheryMiners[msg.sender] = hatcheryMiners[msg.sender] + newMiners;
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;

        //send referral eggs
        claimedEggs[referrals[msg.sender]] =
            claimedEggs[referrals[msg.sender]] +
            eggsUsed /
            10;

        //boost market to nerf miners hoarding
        marketEggs = marketEggs + eggsUsed / 5;
    }

    function sellEggs() public {
        require(initialized, "Not initialized");
        uint256 hasEggs = getMyEggs();
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        uint256 fee2 = fee / 2;
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs = marketEggs + hasEggs;
        treasury1.transfer(fee2);
        treasury2.transfer(fee - fee2);
        msg.sender.transfer(eggValue - fee);
    }

    function buyEggs(address ref) public payable {
        require(initialized, "Not initialized");
        uint256 eggsBought = calculateEggBuy(
            msg.value,
            address(this).balance - msg.value
        );
        eggsBought = eggsBought - devFee(eggsBought);
        uint256 fee = devFee(msg.value);
        uint256 fee2 = fee / 2;
        claimedEggs[msg.sender] = claimedEggs[msg.sender] + eggsBought;
        treasury1.transfer(fee2);
        treasury2.transfer(fee - fee2);
        hatchEggs(ref);
    }

    //magic trade balancing algorithm
    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public view returns (uint256) {
        //(PSN*bs)/(PSNH+((PSN*rs+PSNH*rt)/rt));
        return (PSN * bs) / (PSNH + (PSN * rs + PSNH * rt) / rt);
    }

    function calculateEggSell(uint256 eggs) public view returns (uint256) {
        return calculateTrade(eggs, marketEggs, address(this).balance);
    }

    function calculateEggBuy(uint256 eth, uint256 contractBalance)
        public
        view
        returns (uint256)
    {
        return calculateTrade(eth, contractBalance, marketEggs);
    }

    function calculateEggBuySimple(uint256 eth) public view returns (uint256) {
        return calculateEggBuy(eth, address(this).balance);
    }

    function devFee(uint256 amount) public pure returns (uint256) {
        return (amount * 5) / 100;
    }

    function seedMarket() public payable {
        require(marketEggs == 0, "marketEggs is not zero");
        initialized = true;
        marketEggs = 2592 * (10**8);
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getMyMiners() public view returns (uint256) {
        return hatcheryMiners[msg.sender];
    }

    function getMyEggs() public view returns (uint256) {
        return claimedEggs[msg.sender] + getEggsSinceLastHatch(msg.sender);
    }

    function getEggsSinceLastHatch(address adr) public view returns (uint256) {
        uint256 secondsPassed = min(
            EGGS_TO_HATCH_1MINERS,
            block.timestamp - lastHatch[adr]
        );
        return secondsPassed * hatcheryMiners[adr];
    }

    function min(uint256 a, uint256 b) private pure returns (uint256) {
        return a < b ? a : b;
    }
}
