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
        const tx2 = await myContract.mintRod({value: ethers.utils.parseEther("1")});
        const tx3 = await myContract.mintRod({value: ethers.utils.parseEther("1")});
        const tx4 = await myContract.mintRod({value: ethers.utils.parseEther("1")});
        const tx5 = await myContract.mintRod({value: ethers.utils.parseEther("1")});

        const receipt = await tx.wait();
        const receipt1 = await tx1.wait();
        const receipt2 = await tx2.wait();
        const receipt3 = await tx3.wait();
        const receipt4 = await tx4.wait();
        const receipt5 = await tx5.wait();

// 通过事件获取 rodType 和 newRodTokenId
        const event = receipt.events.find(event => event.event === 'RodMinted');
        const event1 = receipt1.events.find(event => event.event === 'RodMinted');
        const event2 = receipt2.events.find(event => event.event === 'RodMinted');
        const event3 = receipt3.events.find(event => event.event === 'RodMinted');
        const event4 = receipt4.events.find(event => event.event === 'RodMinted');
        const event5 = receipt5.events.find(event => event.event === 'RodMinted');
        const [playAddress, tokenId, rodType] = event.args;
        const [playAddress1, tokenId1, rodType1] = event1.args;
        const [playAddress2, tokenId2, rodType2] = event2.args;
        const [playAddress3, tokenId3, rodType3] = event3.args;
        const [playAddress4, tokenId4, rodType4] = event4.args;
        const [playAddress5, tokenId5, rodType5] = event5.args;
        console.log("Minted Token ID:", tokenId.toString());
        console.log("Rod Type:", rodType.toString());

        console.log("Minted Token ID 1:", tokenId1.toString());
        console.log("Rod Type 1:", rodType1.toString());
        console.log("Minted Token ID 2:", tokenId2.toString());
        console.log("Rod Type 2:", rodType2.toString());
        console.log("Minted Token ID 3:", tokenId3.toString());
        console.log("Rod Type 3:", rodType3.toString());
        console.log("Minted Token ID 4:", tokenId4.toString());
        console.log("Rod Type 4:", rodType4.toString());
        console.log("Minted Token ID 5:", tokenId5.toString());
        console.log("Rod Type 5:", rodType5.toString());
    });

module.exports = {}
