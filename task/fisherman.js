const {task} = require("hardhat/config")
const ethers = require('ethers');
const {json} = require("hardhat/internal/core/params/argumentTypes");

task("fisherman", "fisherman-MaeStrive")
    .setAction(async (taskArgs) => {
        const {ethers} = hre;
        const signers = await ethers.getSigners();
        const deployAddress = signers[0].address;
        const userAddress = signers[1].address;
        // 获取合约 ABI
        const MyContract = await ethers.getContractFactory("FishermanNFT");
        const myContract = await MyContract.deploy(ethers.utils.parseEther("0.000001"));
        await myContract.deployed();
        // 等待交易被矿工打包
        const tx = await myContract.mintFisherman({value: ethers.utils.parseEther("1")});
        const tx1 = await myContract.mintFisherman({value: ethers.utils.parseEther("1")});
        const tx2 = await myContract.mintFisherman({value: ethers.utils.parseEther("1")});
        const tx3 = await myContract.mintFisherman({value: ethers.utils.parseEther("1")});
        const tx4 = await myContract.mintFisherman({value: ethers.utils.parseEther("1")});
        const tx5 = await myContract.mintFisherman({value: ethers.utils.parseEther("1")});

        const receipt = await tx.wait();
        const receipt1 = await tx1.wait();
        const receipt2 = await tx2.wait();
        const receipt3 = await tx3.wait();
        const receipt4 = await tx4.wait();
        const receipt5 = await tx5.wait();

        // 通过事件获取 rodType 和 newRodTokenId
        const event = receipt.events.find(event => event.event === 'FishermanMinted');
        const event1 = receipt1.events.find(event => event.event === 'FishermanMinted');
        const event2 = receipt2.events.find(event => event.event === 'FishermanMinted');
        const event3 = receipt3.events.find(event => event.event === 'FishermanMinted');
        const event4 = receipt4.events.find(event => event.event === 'FishermanMinted');
        const event5 = receipt5.events.find(event => event.event === 'FishermanMinted');
        const [playAddress, tokenId, fishermanType] = event.args;
        const [playAddress1, tokenId1, fishermanType1] = event1.args;
        const [playAddress2, tokenId2, fishermanType2] = event2.args;
        const [playAddress3, tokenId3, fishermanType3] = event3.args;
        const [playAddress4, tokenId4, fishermanType4] = event4.args;
        const [playAddress5, tokenId5, fishermanType5] = event5.args;
        console.log("Minted Token ID:", tokenId.toString());
        console.log("Fisherman Type:", fishermanType.toString());

        console.log("Minted Token ID 1:", tokenId1.toString());
        console.log("Fisherman Type 1:", fishermanType1.toString());
        console.log("Minted Token ID 2:", tokenId2.toString());
        console.log("Fisherman Type 2:", fishermanType2.toString());
        console.log("Minted Token ID 3:", tokenId3.toString());
        console.log("Fisherman Type 3:", fishermanType3.toString());
        console.log("Minted Token ID 4:", tokenId4.toString());
        console.log("Fisherman Type 4:", fishermanType4.toString());
        console.log("Minted Token ID 5:", tokenId5.toString());
        console.log("Fisherman Type 5:", fishermanType5.toString());


        const ownNft = await myContract.getOwnedNFTs(deployAddress);
        const tokenURI = await myContract.tokenURI(3);
        const fishermanType666 = await myContract.getFishermanTypeByTokenId(0);
        console.log(ownNft)
        console.log(tokenURI)
        console.log(fishermanType666)
    });

module.exports = {}
