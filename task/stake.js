const {task} = require("hardhat/config")
const ethers = require('ethers');


function sleep(ms) {
    return new Promise(resolve => setTimeout(resolve, ms));
}


task("stake", "stake-MaeStrive")
    .setAction(async (taskArgs) => {
        const {ethers} = hre;
        const signers = await ethers.getSigners();
        const deployAddress = signers[0].address;
        const userAddress = signers[1].address;
        // GMC合约
        const GMCContract = await ethers.getContractFactory("GMC");
        const gMCContract = await GMCContract.deploy(100000000);
        await gMCContract.deployed();
        //User合约
        const UserContract = await ethers.getContractFactory("User")
        const userContract = await UserContract.deploy(gMCContract.address, 50);
        await userContract.deployed();
        //OOC合约
        const OOCContract = await ethers.getContractFactory("OOC");
        const oOCContract = await OOCContract.deploy(100000000);
        await oOCContract.deployed();
        await gMCContract.addAdmin(userContract.address)
        await userContract.addUser(userAddress)
        await userContract.setCollectedGMC(userAddress, 10000000000)
        //claim GMC
        await userContract.claimGMC(userAddress, 10000000000)
        // await userContract.buyBaits(userAddress, 2)
        //Stake合约
        const StackContract = await ethers.getContractFactory("StakeOld.sol")
        const stackContract = await StackContract.deploy(gMCContract.address, oOCContract.address);
        await stackContract.deployed();
        await gMCContract.addAdmin(stackContract.address)
        const gmcBanlance=await gMCContract.connect(signers[1]).balanceOf(userAddress);
        console.log(gmcBanlance)
        await stackContract.notifyRewardAmount(5);
        await stackContract.connect(signers[1]).stake(10000000000);
        const gmcBanlance1=await gMCContract.connect(signers[1]).balanceOf(userAddress);
        console.log(gmcBanlance1)
        // await sleep(1000 * 60 * 10)
        // const earn = await stackContract.connect(signers[1]).earned(userAddress);
        // console.log("earn", earn)
    });

module.exports = {}
