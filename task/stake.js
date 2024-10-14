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
        await userContract.setCollectedGMC(userAddress, 800)
        //claim GMC
        await userContract.claimGMC(userAddress, 600)
        await userContract.buyBaits(userAddress, 2)
        //Stake合约
        const StackContract = await ethers.getContractFactory("Stake")
        const stackContract = await StackContract.deploy(gMCContract.address, oOCContract.address, 1000000);
        await stackContract.deployed();
        await gMCContract.addAdmin(stackContract.address)
        await stackContract.stake(600);
        await stackContract.connect(signers[1]).stake(500);
        const shareAdmin = await stackContract.getShare();
        const shareUser = await stackContract.connect(signers[1]).getShare();
        const totalShares = await stackContract.connect(signers[1]).totalShares();
        console.log(shareAdmin)
        console.log(shareUser)
        console.log(totalShares)
        await sleep(100000)
        const reword = await stackContract.connect(signers[1]).withdrawdReword();
        console.log(reword)
        await stackContract.connect(signers[1]).withdraw(100);
        const userOOCBalance = await oOCContract.connect(signers[1]).balanceOf(signers[1].address);
        console.log(userOOCBalance)
    });

module.exports = {}
