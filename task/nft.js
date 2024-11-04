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
        const mintedSupplies=await fishermanNFT.mintedSupplies(0)
        console.log(mintedSupplies)
        const maxSupplies=await fishermanNFT.maxSupplies(0)
        console.log(maxSupplies)
        await fishermanNFT.setMaxSupplies([90000,50000,40000,30000])
        const mintedSupplies1=await fishermanNFT.mintedSupplies(3)
        console.log(mintedSupplies1)
        const maxSupplies1=await fishermanNFT.maxSupplies(3)
        console.log(maxSupplies1)
        await fishingRodNFT.mintRod({value: ethers.utils.parseEther("1")});
        await fishingRodNFT.freeMintRod(deployAddress);
        const GMCContract = await ethers.getContractFactory("GMC");
        const gmcContract = await GMCContract.deploy(10000000000)
        await gmcContract.deployed();
        const UserContract = await ethers.getContractFactory("User");
        const userContract = await UserContract.deploy(gmcContract.address, fishermanNFT.address, fishingRodNFT.address)
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
        // console.log(nfts)
        await gmcContract.addAdmin(userContract.address)
        await gmcContract.setUserContractAddress(userContract.address)
        // await userContract.setCollectedGMC(deployAddress, ethers800)
        await userContract.claimGMC(userAddress, ethers.utils.parseEther("5"))
        const gmcBalance=await gmcContract.balanceOf(userAddress)
        console.log("gmcBalance:",gmcBalance)
        await userContract.buyBaits(49)
        // await userContract.connect(signers[1]).buyBaits(1)
        const gmcBalance1=await gmcContract.balanceOf(userAddress)
        const gmcBalanceAdmin=await gmcContract.balanceOf(deployAddress)
        console.log("gmcBalance1:",gmcBalance1)
        console.log("gmcBalanceAdmin:",gmcBalanceAdmin)
        await userContract.buyBaitsAdmin(userAddress,1)
        const gmcBalanceAdmin1=await gmcContract.balanceOf(deployAddress)
        console.log("gmcBalanceAdmin1:",gmcBalanceAdmin1)
        const gmcBalance2=await gmcContract.balanceOf(userAddress)
        console.log("gmcBalance2:",gmcBalance2)

    });

module.exports = {}
