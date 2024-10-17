const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("FishingRodNFT", function () {
    let FishingRodNFT;
    let fishingRodNFT;
    let owner;
    let addr1;
    let addr2;
    const mintPrice = ethers.utils.parseEther("0.1");

    beforeEach(async function () {
        FishingRodNFT = await ethers.getContractFactory("FishingRodNFT");
        [owner, addr1, addr2] = await ethers.getSigners();
        fishingRodNFT = await FishingRodNFT.deploy(mintPrice);
        await fishingRodNFT.deployed();
    });

    describe("Minting", function () {
        it("should mint a new NFT", async function () {
            await fishingRodNFT.connect(addr1).mintRod({ value: mintPrice });
            expect(await fishingRodNFT.balanceOf(addr1.address)).to.equal(1);
        });

        it("should fail if payment is insufficient", async function () {
            await expect(
                fishingRodNFT.connect(addr1).mintRod({ value: ethers.utils.parseEther("0.05") })
            ).to.be.revertedWith("Insufficient payment");
        });
    });

    describe("Listing and Buying", function () {
        beforeEach(async function () {
            await fishingRodNFT.connect(addr1).mintRod({ value: mintPrice });
        });

        it("should list an NFT for sale", async function () {
            await fishingRodNFT.connect(addr1).listItem(0, ethers.utils.parseEther("0.2"));
            const listing = await fishingRodNFT.listings(0);
            expect(listing.price).to.equal(ethers.utils.parseEther("0.2"));
        });

        it("should allow buying an NFT", async function () {
            await fishingRodNFT.connect(addr1).listItem(0, ethers.utils.parseEther("0.2"));
            await fishingRodNFT.connect(addr2).buyItem(0, { value: ethers.utils.parseEther("0.2") });
            expect(await fishingRodNFT.balanceOf(addr2.address)).to.equal(1);
        });

        it("should fail if the price is incorrect", async function () {
            await fishingRodNFT.connect(addr1).listItem(0, ethers.utils.parseEther("0.2"));
            await expect(
                fishingRodNFT.connect(addr2).buyItem(0, { value: ethers.utils.parseEther("0.1") })
            ).to.be.revertedWith("Incorrect price");
        });
    });

    describe("Ownership and Admin Functions", function () {
        it("should allow the owner to withdraw funds", async function () {
            await fishingRodNFT.connect(addr1).mintRod({ value: mintPrice });
            const initialBalance = await ethers.provider.getBalance(owner.address);
            await fishingRodNFT.withdraw();
            const finalBalance = await ethers.provider.getBalance(owner.address);
            expect(finalBalance).to.be.gt(initialBalance);
        });

        it("should allow admin to set new mint price", async function () {
            await fishingRodNFT.setMintPrice(ethers.utils.parseEther("0.2"));
            expect(await fishingRodNFT.mintPrice()).to.equal(ethers.utils.parseEther("0.2"));
        });
    });
});
