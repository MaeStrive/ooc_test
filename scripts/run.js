const { utils } = require("ethers");

async function main() {

    // Get owner/deployer's wallet address
    const [owner] = await hre.ethers.getSigners();

    // Get contract that we want to deploy
    const contractFactory = await hre.ethers.getContractFactory("Stake");

    // Deploy contract with the correct constructor arguments
    const contract = await contractFactory.deploy("0xF722B0cB5F288e07c72FB15dAe14C08d21D6FAf5","0x1fa604416E0a648Fe516819ad7498916b668f7d5",100);
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

