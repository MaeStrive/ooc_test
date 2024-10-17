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

        //FishingSpot
        const FishSpotContract = await ethers.getContractFactory("FishingSpot");
        const fishSpotContract = await FishSpotContract.deploy();
        await fishSpotContract.deployed();
        const fishList = [
            {
                id: 1,
                fishName: "Salmon",
                res: "salmon.png",
                rarityID: 1,
                rarityNum: 10,
                fishFarm: 101,
                fishFramName: "Salmon Farm",
                price: 100,
                output: 10,
                rarity: "Common",
            },
            {
                id: 2,
                fishName: "Tuna",
                res: "tuna.png",
                rarityID: 2,
                rarityNum: 5,
                fishFarm: 102,
                fishFramName: "Tuna Farm",
                price: 200,
                output: 20,
                rarity: "Rare",
            },
        ];
        await fishSpotContract.addFishingSpot(1001, "Summer Fishing Spot", fishList, 1)
        const spotConfig = await fishSpotContract.getFishingSpotConfig(1001)
console.log(spotConfig)
        //User合约
        const UserContract = await ethers.getContractFactory("OOC")

        const userContract = await UserContract.deploy(gMCContract.address, 50);

        await userContract.deployed();
        const gmcSupply = await gMCContract.totalSupply()
        console.log("gmcSupply:", gmcSupply)

        await userContract.setExperienceConfig([10, 15, 20, 25, 30, 35, 40, 45, 50, 55, 60, 65, 70, 75, 80, 85, 90, 95, 100, 105,
            110, 115, 120, 125, 130, 135, 140, 145, 150, 155, 160, 165, 170, 175, 180, 185,
            190, 195, 200, 205, 210, 215, 220, 225, 230, 235, 240, 245, 250, 255]
        )
        await userContract.addUser(userAddress)
        // const exc = await userContract.getExperienceConfig()
        // console.log(exc)
        await userContract.addExperience(userAddress, 30)
        const userLevel = await userContract.getPlayerLevel(userAddress)
        console.log(userLevel)
        const userExperience = await userContract.getExperience(userAddress)
        console.log(userExperience)
        // gMCContract.addAdmin(userContract.address)
        //
        // const gmcCollectedCount = await userContract.getGMCBalance(userAddress)
        // const gmcCount = await userContract.getCollectedGMC(userAddress)
        // console.log("gmcCount:", gmcCount)
        // console.log("gmcCollectedCount:", gmcCollectedCount)
        // await userContract.setCollectedGMC(userAddress, 800)
        // //claim GMC
        // await userContract.claimGMC(userAddress, 120)
        // const gmcCount1 = await userContract.getGMCBalance(userAddress)
        // const gmcCollectedCount1 = await userContract.getCollectedGMC(userAddress)
        // console.log("gmcCount1:", gmcCount1)
        // console.log("gmcCollectedCount1:", gmcCollectedCount1)
        // await userContract.buyBaits(userAddress, 2)
        // const gmcCount2 = await userContract.getGMCBalance(userAddress)
        // const gmcCollectedCount2 = await userContract.getCollectedGMC(userAddress)
        // console.log("gmcCount2:", gmcCount2)
        // console.log("gmcCollectedCount2:", gmcCollectedCount2)
    });

module.exports = {}
