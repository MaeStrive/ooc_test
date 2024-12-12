const { utils } = require("ethers");

async function main() {

    // Get owner/deployer's wallet address
    const [owner] = await hre.ethers.getSigners();

    // Get contract that we want to deploy
    const contractFactory = await hre.ethers.getContractFactory("StakeOld.sol");

    // Deploy contract with the correct constructor arguments
    // const contract = await contractFactory.deploy("0xF722B0cB5F288e07c72FB15dAe14C08d21D6FAf5","0x270A57D965C41FDFdC49f2E44bE80CDAeb27A65F","0x9286f3b231f40cbCe69F1a09dd68a9D98AD1a080",ethers.utils.parseEther("10"));
  const contract =await contractFactory.deploy("0xDd3C029995381434df640C4157A77441a2937a97","0x1fa604416E0a648Fe516819ad7498916b668f7d5");
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

