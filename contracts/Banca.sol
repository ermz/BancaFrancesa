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


contract Banca is Ownable {
    enum Wagers { HIGH, LOW, ACES }

    address payable bancaOwner;

    // Chainlink variables
    uint64 s_subscriptionId;
    bytes32 s_keyHash;
    uint32 callbackGasLimit = 100000;
    uint32 requestConfirmations = 3;
    uint32 constant RANDOM_VALUES = 3; // Three dice values

    event GameResult(address player, Wagers wager, uint256 amountWon);

    constructor(uint64 subscriptionId, bytes32 keyHash) {
        s_subscriptionId = subscriptionId;
        s_keyHash = keyHash;
        bancaOwner = payable(msg.sender);
    }

    function playFrancesa(Wagers _wager) payable public {
        require(msg.value > 100);
        uint256 amountWon;

        uint256 sumResult;

        // Code will run while sumResult doesn't equal 3(Aces), 5-7(Low) or 14-16(High)
        while (sumResult >= 3 || sumResult >= 5 && sumResult <= 7 || sumResult >= 14 && sumResult <= 16) {
            break;
        }

        //

        if (_wager == Wagers.HIGH || _wager == Wagers.LOW) {
            // Pay one to one + some token
            // Percentage based on amount bet
            amountWon = msg.value * 2;
            payable(msg.sender).transfer(amountWon);
        } else if (_wager == Wagers.ACES) {
            amountWon = msg.value * 61;
            payable(msg.sender).transfer(amountWon);
        }

        emit GameResult(msg.sender, _wager, amountWon);
    }

}