const {task} = require("hardhat/config")
const ethers = require('ethers');
const {json} = require("hardhat/internal/core/params/argumentTypes");

task("rod", "rod-MaeStrive")
    .setAction(async (taskArgs) => {
        const {ethers} = hre;
        const signers = await ethers.getSigners();
        const deployAddress = signers[0].address;
        const userAddress = signers[1].address;
        // 获取合约 ABI
        const MyContract = await ethers.getContractFactory("FishingRodNFT");
        const myContract = await MyContract.deploy(ethers.utils.parseEther("0.000001"));
        await myContract.deployed();
        // 等待交易被矿工打包
        const tx = await myContract.freeMintRod(signers[1].address);
        const tx1 = await myContract.mintRod({value: ethers.utils.parseEther("1")});

        const receipt = await tx.wait();
        const receipt1 = await tx1.wait();

// 通过事件获取 rodType 和 newRodTokenId
        const event = receipt.events.find(event => event.event === 'RodMinted');
        const event1 = receipt1.events.find(event => event.event === 'RodMinted');
        const [playAddress, tokenId, rodType] = event.args;
        const [playAddress1, tokenId1, rodType1] = event1.args;
        console.log("Minted Token ID:", tokenId.toString());
        console.log("Rod Type:", rodType.toString());

        console.log("Minted Token ID 1:", tokenId1.toString());
        console.log("Rod Type 1:", rodType1.toString());
    });

module.exports = {}
