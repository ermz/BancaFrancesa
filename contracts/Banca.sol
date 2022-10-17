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


import "@openzeppelin/contracts/access/Ownable.sol";
import "./BancaHelper.sol";

import '@chainlink/contracts/src/v0.8/interfaces/VRFCoordinatorV2Interface.sol';
import '@chainlink/contracts/src/v0.8/VRFConsumerBaseV2.sol';


contract Banca is VRFConsumerBaseV2, Ownable {
    enum Wagers { HIGH, LOW, ACES }

    address payable bancaOwner;
    uint256 private s_lastRoll;

    // Chainlink variables
    uint64 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 callbackGasLimit = 100000;
    uint16 requestConfirmations = 3;
    uint32 constant RANDOM_VALUES = 3; // Three dice values

    VRFCoordinatorV2Interface COORDINATOR;

    event GameResult(address player, Wagers wager, uint256 amountWon);

    constructor(uint64 subscriptionId, bytes32 keyHash) VRFConsumerBaseV2(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D) {
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        bancaOwner = payable(msg.sender);

        COORDINATOR = VRFCoordinatorV2Interface(0x2Ca8E0C643bDe4C2E08ab1fA0da3401AdAD7734D);
    }

    function requestRandomRoll() internal onlyOwner returns (uint256 requestId){
        requestId = COORDINATOR.requestRandomWords(
            s_keyHash,
            s_subscriptionId,
            requestConfirmations,
            callbackGasLimit,
            RANDOM_VALUES
        );
    }

    function fulfillRandomWords(uint256 /* _requestId */, uint256[] memory _randomWords) internal override {
        // Number of sides on a dice 6
        // RandomNum % 6 will equal a number between 0 and 5
        // Add by 1 to get a number between 1 and 6
        // Add three values to calculate result from roll
        uint256 rollAmount = (_randomWords[0] % 6 + 1) + (_randomWords[1] % 6 + 1) + (_randomWords[2] % 6 + 1);
        s_lastRoll = rollAmount;
    }

    function playFrancesa(Wagers _wager) payable public {
        require(msg.value > 100);
        uint256 amountWon;

        uint256 sumResult;

        // Code will run while sumResult doesn't equal 3(Aces), 5-7(Low) or 14-16(High)
        // added break temporarily, to not loop nonstop
        while (sumResult >= 3 || sumResult >= 5 && sumResult <= 7 || sumResult >= 14 && sumResult <= 16) {
            requestRandomRoll();
            sumResult = s_lastRoll;
            break;
        }

        if (sumResult >= 14 && sumResult <= 16 && uint256(_wager) >= 14 && uint256(_wager) <= 16) {
            // Pay one to one + some token
            // Percentage based on amount bet
            amountWon = msg.value * 2;
            payable(msg.sender).transfer(amountWon);
        } else if (sumResult >= 5 && sumResult <= 7 && uint256(_wager) >= 5 && uint256(_wager) <= 7) {
            // Pay one to one + some token
            // Percentage based on amount bet
            amountWon = msg.value * 2;
            payable(msg.sender).transfer(amountWon);
        } else if (sumResult == 3 && uint256(_wager) == 3) {
            amountWon = msg.value * 61;
            payable(msg.sender).transfer(amountWon);
        }

        emit GameResult(msg.sender, _wager, amountWon);
    }

}
