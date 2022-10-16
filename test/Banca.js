const { expect } = require("chai");

describe("Banca", function() {
    const [owner, player1, player2, player3, player4] = await ethers.getSigners();

    const Banca = await ethers.getContractFactory("Banca");
    const banca = await Lock.deploy();

    describe("JoinGame", function () {
        
    })

})