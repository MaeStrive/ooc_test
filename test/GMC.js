const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GMC Token Contract", function () {
    let GMC;
    let gmc;
    let owner;
    let admin;
    let addr1;
    let addr2;
    let initialSupply =100000
    beforeEach(async function () {
        GMC = await ethers.getContractFactory("GMC");
        [owner, admin, addr1, addr2] = await ethers.getSigners();
        gmc = await GMC.deploy(initialSupply);
        await gmc.deployed();
    });

    it("Should set the right owner", async function () {
        expect(await gmc.owner()).to.equal(owner.address);
    });

    it("Should have correct initial supply", async function () {
        const totalSupply = await gmc.totalSupply();
        expect(totalSupply).to.equal(initialSupply);
    });

    it("Should allow owner to add and remove an admin", async function () {
        await gmc.addAdmin(admin.address);
        expect(await gmc.isAdmin(admin.address)).to.be.true;

        await gmc.removeAdmin(admin.address);
        expect(await gmc.isAdmin(admin.address)).to.be.false;
    });

    it("Should not allow non-owner to add admin", async function () {
        await expect(gmc.connect(addr1).addAdmin(addr2.address)).to.be.revertedWith("Ownable: caller is not the owner");
    });

    it("Should allow admin to mint tokens", async function () {
        await gmc.addAdmin(admin.address);
        const mintAmount = ethers.utils.parseEther("1000");

        await gmc.connect(admin).mint(addr1.address, mintAmount);
        expect(await gmc.balanceOf(addr1.address)).to.equal(mintAmount);
    });

    it("Should not allow non-admin to mint tokens", async function () {
        const mintAmount = ethers.utils.parseEther("1000");
        await expect(gmc.connect(addr1).mint(addr2.address, mintAmount)).to.be.revertedWith("GMC: IS NOT ADMIN");
    });

    it("Should allow admin to transfer tokens on behalf of others", async function () {
        const transferAmount = ethers.utils.parseEther("500");

        // Mint tokens to addr1 first
        await gmc.addAdmin(admin.address);
        await gmc.connect(admin).mint(addr1.address, transferAmount);

        // Admin transfers from addr1 to addr2
        await gmc.connect(admin).transfer(addr1.address, addr2.address, transferAmount);

        expect(await gmc.balanceOf(addr2.address)).to.equal(transferAmount);
        expect(await gmc.balanceOf(addr1.address)).to.equal(0);
    });

    it("Should not allow non-admin to transfer tokens on behalf of others", async function () {
        const transferAmount = ethers.utils.parseEther("500");

        await expect(gmc.connect(addr1).transfer(addr2.address, admin.address, transferAmount)).to.be.revertedWith("GMC: IS NOT ADMIN");
    });

    it("Should transfer ownership", async function () {
        await gmc.transferOwnership(addr1.address);
        expect(await gmc.owner()).to.equal(addr1.address);
    });

    it("Should not allow non-owner to transfer ownership", async function () {
        await expect(gmc.connect(addr1).transferOwnership(addr2.address)).to.be.revertedWith("Ownable: caller is not the owner");
    });
});
