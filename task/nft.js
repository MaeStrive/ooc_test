const {task} = require("hardhat/config")
const ethers = require('ethers');

task("nft", "nft-MaeStrive")
    .setAction(async (taskArgs) => {
        const {ethers} = hre;
        const signers = await ethers.getSigners();
        const deployAddress = signers[0].address;
        const userAddress = signers[1].address;
        // 获取合约 ABI
        const FishermanNFT = await ethers.getContractFactory("FishermanNFT");
        const fishermanNFT = await FishermanNFT.deploy(ethers.utils.parseEther("0.00001"));
        await fishermanNFT.deployed();
        await fishermanNFT.mintFisherman({value: ethers.utils.parseEther("1")});
        const FishingRodNFT = await ethers.getContractFactory("FishingRodNFT");
        const fishingRodNFT = await FishingRodNFT.deploy(ethers.utils.parseEther("0.00001"));
        await fishingRodNFT.deployed();
        await fishingRodNFT.mintRod({value: ethers.utils.parseEther("1")});
        await fishingRodNFT.freeMintRod(deployAddress);
        const GMCContract = await ethers.getContractFactory("GMC");
        const gmcContract = await GMCContract.deploy(ethers.utils.parseEther("1"))
        await gmcContract.deployed();
        const UserContract = await ethers.getContractFactory("User");
        const userContract = await UserContract.deploy(gmcContract.address, fishermanNFT.address, fishingRodNFT.address, ethers.utils.parseEther("10"))
        await userContract.deployed();
        const rodType = await fishingRodNFT.getRodTypeByTokenId(0)
        const rodType1 = await fishingRodNFT.getRodTypeByTokenId(1)
        await userContract.addUser(deployAddress)
        await userContract.addUser(userAddress)
        // console.log(rodType)
        // console.log(rodType1)
        // console.log(currentFisherman)
        // 模拟玩家数据
        const player1Data = {
            fishingCount: 10,
            experience: 100,
            level: 2,
            unlockedFishingSpots: [1, 2, 3, 0, 0],
            currentFishingSpot: 1,
            fishPoolLevel: 2,
            interestRate: 5,
            collectedGMC: ethers.utils.parseEther("10"),
            baitCount: 50,
            fishCount: [5, 2, 0, 0, 0, 0, 0, 0, 0, 0],
            currentFishermanNFT: 2,
            currentRodNFT: 3,
        };

        const player2Data = {
            fishingCount: 15,
            experience: 200,
            level: 3,
            unlockedFishingSpots: [1, 2, 3, 4, 0],
            currentFishingSpot: 2,
            fishPoolLevel: 3,
            interestRate: 6,
            collectedGMC: ethers.utils.parseEther("15"),
            baitCount: 60,
            fishCount: [10, 4, 0, 0, 0, 0, 0, 0, 0, 0],
            currentFishermanNFT: 1,
            currentRodNFT: 4,
        };
        const playerData = [player1Data, player2Data]
        const addresses = [deployAddress, userAddress]
        await userContract.updateUserData(playerData, addresses)
        const playerInfo = await userContract.getPlayerInfo(userAddress)
        // console.log(playerInfo)
        await userContract.changeRod(1, deployAddress)


       const nfts= await fishingRodNFT.getOwnedNFTs(deployAddress)
        console.log(nfts)
    });

module.exports = {}
