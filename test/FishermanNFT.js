const {expect} = require("chai");
const { loadFixture } =require("@nomicfoundation/hardhat-network-helpers")
const {ethers} = hre;

describe("FishermanNFT",  function () {

    // const {ethers} = hre;
    const mintPrice = ethers.utils.parseEther("0.000001");

    let owner,addr1,addr2;
    async function deployTokenFixture() {
         [owner, addr1, addr2] =  await ethers.getSigners();
        const FishermanNFT = await ethers.getContractFactory("FishermanNFT");
        const fishermanNFT = await FishermanNFT.deploy(mintPrice);
        await fishermanNFT.deployed();
        return { FishermanNFT, fishermanNFT, owner, addr1, addr2 };
    }


    describe("Deployment", function () {
        it("Should set the correct owner", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            expect(await fishermanNFT.owner()).to.equal(owner.address);
        });

        // it("Should set the correct mint price", async function () {
        //     const { fishermanNFT, owner } = await loadFixture(
        //         deployTokenFixture
        //     );
        //     expect(await fishermanNFT.mintPrice()).to.equal(mintPrice);
        // });
    });

    describe("Minting Fisherman", function () {
        it("Should mint fisherman if correct payment is sent", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            const tx = await fishermanNFT.connect(addr1).mintFisherman({value: ethers.utils.parseEther("0.0001")});
            const receipt = await tx.wait();
            expect(await fishermanNFT.balanceOf(addr1.address)).to.equal(1);
            expect(await fishermanNFT.ownerOf(0)).to.equal(addr1.address);
        });

        it("Should fail to mint if not enough ETH is sent", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            await expect(
                fishermanNFT.connect(addr1).mintFisherman({value: ethers.utils.parseEther("0.000000005")})
            ).to.be.revertedWith("Insufficient payment");
        });

        it("Should increment tokenId on mint", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            const tx1 = await fishermanNFT.connect(addr1).mintFisherman({value: mintPrice});

            const tx2 = await fishermanNFT.connect(addr1).mintFisherman({value: mintPrice});
        });

        it("Should revert if max supply for a fisherman type is reached", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            // Minting all low-quality fisherman
                await fishermanNFT.connect(owner).freeMintFisherman(addr1.address);

            // // Try to mint after max supply is reached
            // await expect(
            //     fishermanNFT.connect(owner).freeMintFisherman(addr1.address)
            // ).to.be.revertedWith("Max supply reached for this type");
        });
    });

    describe("Listing and buying NFTs", function () {

        it("Should allow listing an item for sale", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            const tx1 = await fishermanNFT.connect(addr1).mintFisherman({value: mintPrice});

            await fishermanNFT.connect(addr1).listItem(0, ethers.utils.parseEther("0.05"));

            const listing = await fishermanNFT.listings(0);
            expect(listing.seller).to.equal(addr1.address);
            expect(listing.price).to.equal(ethers.utils.parseEther("0.05"));
        });

        it("Should allow buying a listed item", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            const tx1 = await fishermanNFT.connect(addr1).mintFisherman({value: mintPrice});

            await fishermanNFT.connect(addr1).listItem(0, ethers.utils.parseEther("0.05"));

            await fishermanNFT.connect(addr2).buyItem(0, {value: ethers.utils.parseEther("0.05")});

            expect(await fishermanNFT.ownerOf(0)).to.equal(addr2.address);
        });

        it("Should fail to buy if incorrect price is sent", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            const tx1 = await fishermanNFT.connect(addr1).mintFisherman({value: mintPrice});

            await fishermanNFT.connect(addr1).listItem(0, ethers.utils.parseEther("0.05"));

            await expect(
                fishermanNFT.connect(addr2).buyItem(0, {value: ethers.utils.parseEther("0.01")})
            ).to.be.revertedWith("Incorrect price");
        });

        it("Should transfer funds to the seller upon purchase", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            const tx1 = await fishermanNFT.connect(addr1).mintFisherman({value: mintPrice});

            await fishermanNFT.connect(addr1).listItem(0, ethers.utils.parseEther("0.05"));

            const sellerBalanceBefore = await ethers.provider.getBalance(addr1.address);

            await fishermanNFT.connect(addr2).buyItem(0, {value: ethers.utils.parseEther("0.05")});

            const sellerBalanceAfter = await ethers.provider.getBalance(addr1.address);
            expect(sellerBalanceAfter.sub(sellerBalanceBefore)).to.equal(ethers.utils.parseEther("0.05"));
        });

        it("Should allow cancelling a listing", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            const tx1 = await fishermanNFT.connect(addr1).mintFisherman({value: mintPrice});

            await fishermanNFT.connect(addr1).listItem(0, ethers.utils.parseEther("0.05"));

            await fishermanNFT.connect(addr1).cancelListing(0);

            const listing = await fishermanNFT.listings(0);
            expect(listing.price).to.equal(0);  // Listing should be deleted
        });
    });

    describe("Admin functions", function () {

        it("Should allow admin to free mint a fisherman", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );

            await fishermanNFT.connect(owner).freeMintFisherman(addr2.address);

            expect(await fishermanNFT.balanceOf(addr2.address)).to.equal(1);
        });

        it("Should allow admin to set a new mint price", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            const newMintPrice = ethers.utils.parseEther("0.02");
            await fishermanNFT.connect(owner).setMintPrice(newMintPrice);

            expect(await fishermanNFT.mintPrice()).to.equal(newMintPrice);
        });

        it("Should allow admin to change base token URI", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            const newBaseTokenURI = "ipfs://newbaseuri/";
            await fishermanNFT.connect(owner).setBaseTokenURI(newBaseTokenURI);

            // expect(await fishermanNFT._baseURI()).to.equal(newBaseTokenURI);
        });

        it("Should not allow non-admin to free mint", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            await expect(
                fishermanNFT.connect(addr1).freeMintFisherman(addr2.address)
            ).to.be.revertedWith("Caller is not an admin");
        });
    });

    describe("Utility functions", function () {
        it("Should return owned tokens of an address", async function () {
            const { fishermanNFT, owner } = await loadFixture(
                deployTokenFixture
            );
            await fishermanNFT.connect(addr1).mintFisherman({value: mintPrice});
            await fishermanNFT.connect(addr1).mintFisherman({value: mintPrice});

            const ownedTokens = await fishermanNFT.getOwnedNFTs(addr1.address);
            expect(ownedTokens.length).to.equal(2);
            expect(ownedTokens[0]).to.equal(0);
            expect(ownedTokens[1]).to.equal(1);
        });
    });
});
