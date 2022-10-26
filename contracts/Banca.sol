// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;

// Game starts immediately once they bet and place their wager
// Once game ends, player is paid immediately w/t some additional FCS token based on amount bet

// Wagers available
// High (14, 15, 16)
// Low (5, 6, 7)
// Aces: Three aces

// Win percentage
// Big or Small - 49.2%
// Aces - 1.6%

// Players collect one to one, unless win by aces in which case collet 61 x value bet on
// All losing wagers are collected by Banca


/*
    Potential idea to use both chainlink keepers and random number

    Use chainlink keepers in order to run Request random numbers, but get a quite a couple of random numbers
    It would be more cost effective than running RequestRandomRoll every single time
    Chainlink keeper will only run once the requestId array is at a low enough length

      
*/


import "@openzeppelin/contracts/access/Ownable.sol";
import "./BancaHelper.sol";

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';

import '@chainlink/contracts/src/v0.8/AutomationCompatible.sol';

error Upkeep__NotNeeded(uint256 arrayLength);

contract Banca is VRFConsumerBaseV2, AutomationCompatibleInterface, Ownable {
    enum Wagers { HIGH, LOW, ACES }

    address payable bancaOwner;
    uint256 private s_lastRoll;
    uint256[] private randomNums;
    mapping (address => uint256) playerBalance;

    // Chainlink variables
    uint64 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 10;
    uint32 constant RANDOM_VALUES = 3; // Three dice values

    VRFCoordinatorV2Interface COORDINATOR;

    event GameResult(address player, Wagers wager, uint256 amountWon);
    event RequestRandomNums(uint256 requestId);
    event WithdrawWinnings(address player, uint256 amount);

    constructor(uint64 subscriptionId, bytes32 keyHash) VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) {
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        bancaOwner = payable(msg.sender);

        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
    }

    // function requestRandomRoll() internal onlyOwner returns (uint256 requestId){
    //     requestId = COORDINATOR.requestRandomWords(
    //         s_keyHash,
    //         s_subscriptionId,
    //         requestConfirmations,
    //         callbackGasLimit,
    //         RANDOM_VALUES
    //     );
    // }

    function fulfillRandomWords(uint256 /* _requestId */, uint256[] memory _randomWords) internal override {
        // Number of sides on a dice 6
        // RandomNum % 6 will equal a number between 0 and 5
        // Add by 1 to get a number between 1 and 6
        // Add three values to calculate result from roll

        // Add all 100 dice rolls to randomNums array
        for (uint256 i = 0; i < _randomWords.length; i++) {
            randomNums.push(_randomWords[i] % 6 + 1);
        }
    }

    function checkUpkeep(bytes memory /* checkData */) public override returns (bool upkeepNeeded, bytes memory /* performData */) {
        // Checks that there are less than 50 randon numbers in randomNums array
        bool lowRandomNums = randomNums.length < 50;
        upkeepNeeded = (lowRandomNums);
    }

    function performUpkeep(bytes calldata /* performData */) external override {
        (bool upkeepNeeded,) = checkUpkeep("");

        if(!upkeepNeeded) {
            revert Upkeep__NotNeeded(randomNums.length);
        }

        uint256 requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            RANDOM_VALUES
        );
        emit RequestRandomNums(requestId);
        // Should add 100 random nums to randomNums array
    }

    function playFrancesa(uint256 _wager) payable public {
        require(msg.value > 100);
        uint256 amountWon;

        uint256 sumResult;

        // Code will run while sumResult doesn't equal 3(Aces), 5-7(Low) or 14-16(High)
        // added break temporarily, to not loop nonstop
        while (sumResult >= 3 || sumResult >= 5 && sumResult <= 7 || sumResult >= 14 && sumResult <= 16) {
            // requestRandomRoll();
            // Adds last three numbers in randomNums array
            sumResult = randomNums[randomNums.length - 1] + randomNums[randomNums.length - 2] + randomNums[randomNums.length - 3];
            // Will delete last three number in randomNums array
            removeLastThree();
        }

        if (sumResult >= 14 && sumResult <= 16 && Wagers(_wager) == Wagers.HIGH) {
            // Pay one to one + some token
            // Percentage based on amount bet
            amountWon = msg.value * 2;
            playerBalance[msg.sender] += amountWon;
        } else if (sumResult >= 5 && sumResult <= 7 && Wagers(_wager) == Wagers.LOW) {
            // Pay one to one + some token
            // Percentage based on amount bet
            amountWon = msg.value * 2;
            playerBalance[msg.sender] += amountWon;
        } else if (sumResult == 3 && Wagers(_wager) == Wagers.ACES) {
            amountWon = msg.value * 61;
            playerBalance[msg.sender] += amountWon;
        }

        emit GameResult(msg.sender, Wagers(_wager), amountWon);
    }

    function withdrawBalance() external onlyOwner() {
        // Withdraw all available funds to player
        uint256 totalAmountWon = playerBalance[msg.sender];
        playerBalance[msg.sender] = 0;
        payable(msg.sender).transfer(totalAmountWon);
        emit WithdrawWinnings(msg.sender, totalAmountWon);
    }

    // Helper Functions
    function removeLastThree() public {
        randomNums.pop();
        randomNums.pop();
        randomNums.pop();
    }


}
