const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("OOC Token Contract", function () {
    let OOC;
    let ooc;
    let owner;
    let addr1;
    let addr2;
    let initialSupply = ethers.utils.parseEther("10000");

    beforeEach(async function () {
        OOC = await ethers.getContractFactory("OOC");
        [owner, addr1, addr2] = await ethers.getSigners();
        ooc = await OOC.deploy(initialSupply);
        await ooc.deployed();
    });

    it("Should set the right owner", async function () {
        expect(await ooc.owner()).to.equal(owner.address);
    });

    it("Should have correct initial supply", async function () {
        const totalSupply = await ooc.totalSupply();
        expect(totalSupply).to.equal(initialSupply);
    });

    it("Should allow owner to mint tokens", async function () {
        const mintAmount = ethers.utils.parseEther("1000");

        await ooc.mint(addr1.address, mintAmount);
        expect(await ooc.balanceOf(addr1.address)).to.equal(mintAmount);

        // Ensure that the total supply increases after minting
        const totalSupply = await ooc.totalSupply();
        expect(totalSupply).to.equal(initialSupply.add(mintAmount));
    });

    it("Should emit Mint event when tokens are minted", async function () {
        const mintAmount = ethers.utils.parseEther("500");

        await expect(ooc.mint(addr1.address, mintAmount))
            .to.emit(ooc, "Mint")
            .withArgs(addr1.address, mintAmount);
    });

    it("Should not allow non-owner to mint tokens", async function () {
        const mintAmount = ethers.utils.parseEther("500");
        await expect(ooc.connect(addr1).mint(addr2.address, mintAmount)).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should allow users to burn their tokens", async function () {
        const burnAmount = ethers.utils.parseEther("500");

        // Mint some tokens to addr1 for burning
        await ooc.mint(addr1.address, burnAmount);

        // Burn the tokens from addr1's balance
        await ooc.connect(addr1).burn(burnAmount);

        expect(await ooc.balanceOf(addr1.address)).to.equal(0);

        // Ensure the total supply decreases after burning
        const totalSupply = await ooc.totalSupply();
        expect(totalSupply).to.equal(initialSupply);
    });

    it("Should emit Burn event when tokens are burned", async function () {
        const burnAmount = ethers.utils.parseEther("500");

        // Mint some tokens to addr1 for burning
        await ooc.mint(addr1.address, burnAmount);

        // Ensure the Burn event is emitted
        await expect(ooc.connect(addr1).burn(burnAmount))
            .to.emit(ooc, "Burn")
            .withArgs(addr1.address, burnAmount);
    });

    it("Should transfer ownership", async function () {
        await ooc.transferOwnership(addr1.address);
        expect(await ooc.owner()).to.equal(addr1.address);
    });

    it("Should not allow non-owner to transfer ownership", async function () {
        await expect(ooc.connect(addr1).transferOwnership(addr2.address)).to.be.revertedWith("Ownable: caller is not the owner");
    });
});
