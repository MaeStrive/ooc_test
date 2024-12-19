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


        //OOC合约
        const OOCContract = await ethers.getContractFactory("OOC");
        const oOCContract = await OOCContract.deploy(100000000);
        await oOCContract.deployed();

        //Stake合约
        const StackContract = await ethers.getContractFactory("Stake")
        const stackContract = await StackContract.deploy(oOCContract.address, gMCContract.address, ethers.utils.parseEther("0.502"));
        await stackContract.deployed();

        //授权
        // await gMCContract.approve(stackContract.address, ethers.utils.parseEther("1"));
        await stackContract.approveGmcStake(ethers.utils.parseEther("1"));
        // const gmcBanlance1=await gMCContract.connect(signers[0]).balanceOf(userAddress);
        const gmcBanlance1 = await gMCContract.balanceOf(deployAddress);
        // console.log(gmcBanlance1)
        await stackContract.approveOocStake(ethers.utils.parseEther("1"));

        const oocBanlance1 = await oOCContract.balanceOf(deployAddress);
        console.log(oocBanlance1)
        await stackContract.addReward(ethers.utils.parseEther("1"))
        const rewardPerToken=await stackContract.rewardPerToken()
        console.log(rewardPerToken)

    });

module.exports = {}
