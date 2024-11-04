const {task} = require("hardhat/config")
const ethers = require('ethers');

task("user", "user-MaeStrive")
    .setAction(async (taskArgs) => {
        const {ethers} = hre;
        const signers = await ethers.getSigners();
        const deployAddress = signers[0].address;
        const userAddress = signers[1].address;
        // 获取合约 ABI
        const GMCContract = await ethers.getContractFactory("User");
        const gMCContract = await GMCContract.deploy(10000000);
        await gMCContract.deployed();

        //User合约
        const UserContract = await ethers.getContractFactory("OOC")

        const userContract = await UserContract.deploy(gMCContract.address, 50);

        await userContract.deployed();
        const gmcSupply = await gMCContract.totalSupply()
        console.log("gmcSupply:", gmcSupply)

        await userContract.addUser(userAddress)
        // const exc = await userContract.getExperienceConfig()
        // console.log(exc)
        await userContract.addExperience(userAddress, 30)
        const userLevel = await userContract.getPlayerLevel(userAddress)
        console.log(userLevel)
        const userExperience = await userContract.getExperience(userAddress)
        console.log(userExperience)
        gMCContract.addAdmin(userContract.address)

        const gmcCollectedCount = await userContract.getGMCBalance(userAddress)
        const gmcCount = await userContract.getCollectedGMC(userAddress)
        console.log("gmcCount:", gmcCount)
        console.log("gmcCollectedCount:", gmcCollectedCount)
        await userContract.setCollectedGMC(userAddress, 800)
        //claim GMC
        await userContract.claimGMC(userAddress, 120)
        const gmcCount1 = await userContract.getGMCBalance(userAddress)
        const gmcCollectedCount1 = await userContract.getCollectedGMC(userAddress)
        console.log("gmcCount1:", gmcCount1)
        console.log("gmcCollectedCount1:", gmcCollectedCount1)
        await userContract.buyBaits(userAddress, 2)
        const gmcCount2 = await userContract.getGMCBalance(userAddress)
        const gmcCollectedCount2 = await userContract.getCollectedGMC(userAddress)
        console.log("gmcCount2:", gmcCount2)
        console.log("gmcCollectedCount2:", gmcCollectedCount2)
    });

module.exports = {}
