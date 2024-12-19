const { utils } = require("ethers");

async function main() {

    // Get owner/deployer's wallet address
    const [owner] = await hre.ethers.getSigners();

    // Get contract that we want to deploy
    const contractFactory = await hre.ethers.getContractFactory("Stake");

    // Deploy contract with the correct constructor arguments
    // const contract = await contractFactory.deploy("0xF722B0cB5F288e07c72FB15dAe14C08d21D6FAf5","0x270A57D965C41FDFdC49f2E44bE80CDAeb27A65F","0x9286f3b231f40cbCe69F1a09dd68a9D98AD1a080",ethers.utils.parseEther("10"));
  // const contract =await contractFactory.deploy(ethers.utils.parseEther("0.000000001"));
    const contract =await contractFactory.deploy("0x77545E0c333Da3a3A58ec46da27eb48e71949809","0x01D0B3c7BcaA4a052a03C7001ce1c2c028a24D09",ethers.utils.parseEther("0.502"));
    await contract.deployed()

    // Get contract address
    console.log("Contract deployed to:", contract.address);
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

