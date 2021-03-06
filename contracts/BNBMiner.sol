//SPDX-License-Identifier: MIT

pragma solidity 0.8.7;

contract BNBMiner {
    //uint256 EGGS_PER_MINERS_PER_SECOND=1;
    uint256 public constant EGGS_TO_HATCH_1MINERS = 2592000; //for final version should be seconds in a day
    uint256 constant PSN = 10000;
    uint256 constant PSNH = 5000;
    bool public initialized = false;
    address payable public treasury1;
    address payable public treasury2;
    mapping(address => uint256) public hatcheryMiners;
    mapping(address => uint256) public claimedEggs;
    mapping(address => uint256) public lastHatch;
    mapping(address => address) public referrals;
    uint256 public marketEggs;

    constructor(address payable _treasury1, address payable _treasury2) {
        treasury1 = _treasury1;
        treasury2 = _treasury2;
    }

    function hatchEggs(address ref) public {
        require(initialized, "Not initialized");
        if (ref == msg.sender) {
            ref = address(0);
        }
        if (referrals[msg.sender] == address(0)) {
            referrals[msg.sender] = ref;
        }
        uint256 eggsUsed = getMyEggs(msg.sender);
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

    function sellEggs() external {
        require(initialized, "Not initialized");
        uint256 hasEggs = getMyEggs(msg.sender);
        uint256 eggValue = calculateEggSell(hasEggs);
        uint256 fee = devFee(eggValue);
        uint256 halfFee = fee / 2;
        claimedEggs[msg.sender] = 0;
        lastHatch[msg.sender] = block.timestamp;
        marketEggs = marketEggs + hasEggs;

        (bool sent1, ) = treasury1.call{value: halfFee}("");
        require(sent1, "ETH transfer Fail");

        (bool sent2, ) = treasury2.call{value: fee - halfFee}("");
        require(sent2, "ETH transfer Fail");

        (bool sent, ) = msg.sender.call{value: eggValue - fee}("");
        require(sent, "ETH transfer Fail");
    }

    function buyEggs(address ref) external payable {
        require(initialized, "Not initialized");
        uint256 eggsBought = calculateEggBuy(
            msg.value,
            address(this).balance - msg.value
        );
        eggsBought = eggsBought - devFee(eggsBought);
        uint256 fee = devFee(msg.value);
        uint256 halfFee = fee / 2;
        claimedEggs[msg.sender] = claimedEggs[msg.sender] + eggsBought;

        hatchEggs(ref);

        (bool sent1, ) = treasury1.call{value: halfFee}("");
        require(sent1, "ETH transfer Fail");

        (bool sent2, ) = treasury2.call{value: fee - halfFee}("");
        require(sent2, "ETH transfer Fail");
    }

    //magic trade balancing algorithm
    function calculateTrade(
        uint256 rt,
        uint256 rs,
        uint256 bs
    ) public pure returns (uint256) {
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

    function calculateEggBuySimple(uint256 eth) external view returns (uint256) {
        return calculateEggBuy(eth, address(this).balance);
    }

    function devFee(uint256 amount) public pure returns (uint256) {
        return (amount * 5) / 100;
    }

    function seedMarket() external payable {
        require(marketEggs == 0, "marketEggs is not zero");
        initialized = true;
        marketEggs = 2592 * (10**8);
    }

    function getBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getMyMiners(address account) external view returns (uint256) {
        return hatcheryMiners[account];
    }

    function getMyEggs(address account) public view returns (uint256) {
        return claimedEggs[account] + getEggsSinceLastHatch(account);
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
