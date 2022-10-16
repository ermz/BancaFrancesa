// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.13 <0.9.0;


import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract BancaToken is ERC20 {

    constructor() ERC20("Francesa", "FCS") {}
}