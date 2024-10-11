const {task} = require("hardhat/config")
const ethers = require('ethers');

task("test", "test-MaeStrive")
    .setAction(async (taskArgs) => {
        const {ethers} = hre;
        const signers = await ethers.getSigners();
        const deployAddress = signers[0].address;
        const userAddress = signers[1].address;
        // 获取合约 ABI
        const MyContract = await ethers.getContractFactory("FishermanNFT");
        const myContract = await MyContract.deploy(ethers.utils.parseEther("0.000001"));
        await myContract.deployed();
        // const totalSupply = await myContract.totalSupply();
        // console.log(totalSupply)
        // 调用合约中的函数
        await myContract.mintFisherman({value: ethers.utils.parseEther("1")});
        await myContract.mintFisherman({value: ethers.utils.parseEther("1")});
        await myContract.freeMintFisherman(signers[1].address)
        await myContract.freeMintFisherman(signers[1].address)
        // const value1 = await myContract.tokenURI(0);
        const value11 = await myContract.tokenURI(0)
        const value12 = await myContract.tokenURI(1)
        const value13 = await myContract.tokenURI(2)
        const value14 = await myContract.tokenURI(3)
        // await myContract.connect(signers[1]).mintRod({value: ethers.utils.parseEther("1")})
        const value = await myContract.totalSupply()
        const value2 = await myContract.balanceOf(userAddress)
        // const value13 = await myContract.tokenURI(2)
        // console.log(value13)
        console.log("value2:", value2)
        await myContract.connect(signers[1]).listItem(2, 10000)
        const value3 = await myContract.balanceOf(userAddress)
        console.log("value3:", value3)
        const value05 = await myContract.balanceOf(deployAddress)
        console.log("value05:", value05)
        //
        await myContract.buyItem(2, {value: 10000});
        const value5 = await myContract.balanceOf(deployAddress)
        console.log("value5:", value5)
        console.log(value)
        console.log(value11)
        console.log(value12)
        console.log(value13)
        console.log(value14)
        // console.log(value2)
    });

module.exports = {}
