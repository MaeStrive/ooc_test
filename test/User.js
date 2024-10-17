const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("User Contract Test", function () {
    let OOC, GMC, User;
    let ooc, gmc, user;
    let owner, addr1, addr2;

    beforeEach(async function () {
        // 部署OOC合约
        OOC = await ethers.getContractFactory("OOC");
        [owner, addr1, addr2] = await ethers.getSigners();
        ooc = await OOC.deploy(1000); // 初始化供应量为1000
        await ooc.deployed();

        // 部署GMC合约
        GMC = await ethers.getContractFactory("GMC");
        gmc = await GMC.deploy(1000);
        await gmc.deployed();

        // 部署User合约, 并将GMC合约地址传递进去
        User = await ethers.getContractFactory("User");
        user = await User.deploy(gmc.address, 1); // 传入GMC合约地址和baitPrice
        await user.deployed();
    });

    it("Should deploy GMC and OOC contracts", async function () {
        expect(await ooc.totalSupply()).to.equal(1000 * 10 ** 18);
        expect(await gmc.name()).to.equal("Gold Mine Coin");
    });

    it("Should register a player", async function () {
        await user.addUser(addr1.address);
        const player = await user.getUser(addr1.address);
        expect(player.level).to.equal(1);
    });

    it("Should allow claiming GMC", async function () {
        await user.addUser(addr1.address);

        // 给用户分配收集的GMC
        await user.setCollectedGMC(addr1.address, 100);

        // 管理员调用领取功能
        await user.claimGMC(addr1.address, 50);

        expect(await gmc.balanceOf(addr1.address)).to.equal(50);
    });

    it("Should allow user to buy baits using GMC", async function () {
        await user.addUser(addr1.address);

        // 给addr1铸造一些GMC币
        await gmc.mint(addr1.address, 100);

        // 设置测试用例用户购买10个鱼饵
        await user.buyBaits(addr1.address, 10);

        // 检查用户的鱼饵数量是否增加
        const player = await user.getUser(addr1.address);
        expect(player.baitCount).to.equal(10);
    });
});
