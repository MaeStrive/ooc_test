// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Metadata.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/IERC721Enumerable.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/utils/introspection/ERC165.sol";

contract FishingRodNFT is
Context, ERC165, IERC721, IERC721Metadata,Ownable,IERC721Enumerable
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    Counters.Counter private _tokenIds;

//    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    string private _baseTokenURI = "ipfs://QmNkAXGMdxuZG5SYySe1u5tiEMs51LGB5GwYebtEdrHPvc/";
    uint256 public mintPrice;
    uint256 public transferFee;

    struct RodAttributes {
        string image;
        uint256 qteCount;
        uint256 innerValue;
        uint256 outerValue;
        uint256 comboValue;
        string name;
        string skillName;
        uint256 skillValue;
        string qteSkill;
        uint256 rodId;
    }

    mapping(uint256 => RodAttributes) private _rodAttributes;
    uint256[6] public maxSupplies = [8000, 7000, 6000, 5000, 4000, 500];
    uint256[6] public mintedSupplies;

    mapping(uint256 => uint256) private rodTypes;

    event RodMinted(address indexed to, uint256 indexed tokenId);
    event RodAttributesUpdated(uint256 indexed tokenId);
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);

    constructor(
        uint256 _mintPrice,
        uint256 _transferFee
    )  {
        mintPrice = _mintPrice;
        transferFee = _transferFee;
//        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
//        _setupRole(ADMIN_ROLE, msg.sender);
    }



//    modifier onlyAdmin() {
//        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
//        _;
//    }

    function mintRod() external payable returns (uint256) {
        require(msg.value >= mintPrice, "Insufficient payment");
        uint totalSupply = 0;
        for (uint i = 0; i < maxSupplies.length; i++) {
            totalSupply += maxSupplies[i];
        }
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % totalSupply;
        uint256 rodType = 0;
        for (uint256 i = 0; i < maxSupplies.length; i++) {
            if (randomNumber < mintedSupplies[i] + maxSupplies[i]) {
                rodType = i;
                break;
            }
            randomNumber -= maxSupplies[i];
        }
        require(mintedSupplies[rodType] < maxSupplies[rodType], "Max supply reached for this rod type");

        _tokenIds.increment();
        uint256 newRodTokenId = _tokenIds.current();
        rodTypes[newRodTokenId] = rodType;
        _safeMint(msg.sender, newRodTokenId);

        mintedSupplies[rodType]++;
        emit RodMinted(msg.sender, newRodTokenId);

        if (msg.value > mintPrice) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }
        return newRodTokenId;
    }

    function freeMintRod() external  returns (uint256) {
        uint totalSupply = 0;
        for (uint i = 0; i < maxSupplies.length; i++) {
            totalSupply += maxSupplies[i];
        }
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender))) % totalSupply;
        uint256 rodType = 0;
        for (uint256 i = 0; i < maxSupplies.length; i++) {
            if (randomNumber < mintedSupplies[i] + maxSupplies[i]) {
                rodType = i;
                break;
            }
            randomNumber -= maxSupplies[i];
        }
        require(mintedSupplies[rodType] < maxSupplies[rodType], "Max supply reached for this rod type");

        _tokenIds.increment();
        uint256 newRodTokenId = _tokenIds.current();
        rodTypes[newRodTokenId] = rodType;
        _safeMint(msg.sender, newRodTokenId);

        mintedSupplies[rodType]++;
        emit RodMinted(msg.sender, newRodTokenId);

        return newRodTokenId;
    }

    function getRodAttributes(
        uint256 tokenId
    ) external view returns (RodAttributes memory) {
        require(_exists(tokenId), "Rod does not exist");
        return _rodAttributes[tokenId];
    }

    function updateRodAttributes(
        uint256 tokenId,
        RodAttributes memory newAttributes
    ) external  {
        require(_exists(tokenId), "Rod does not exist");
        _rodAttributes[tokenId] = newAttributes;
        emit RodAttributesUpdated(tokenId);
    }

    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public  virtual override {
        super.transferFrom(from, to, tokenId);
    }

    function safeTransferFrom(
        address from,
        address to,
        uint256 tokenId,
        bytes memory _data
    ) public virtual override {
        super.safeTransferFrom(from, to, tokenId, _data);
    }

    function addAdmin(address newAdmin) external onlyOwner {
//        grantRole(ADMIN_ROLE, newAdmin);
        emit AdminAdded(newAdmin);
    }

    function removeAdmin(address admin) external onlyOwner {
//        revokeRole(ADMIN_ROLE, admin);
        emit AdminRemoved(admin);
    }

    function setBaseTokenURI(string memory newBaseTokenURI) external onlyOwner {
        _baseTokenURI = newBaseTokenURI;
    }

    function setMintPrice(uint256 newMintPrice) external onlyOwner {
        mintPrice = newMintPrice;
    }

    function setTransferFee(uint256 newTransferFee) external onlyOwner {
        transferFee = newTransferFee;
    }

    function transferOwnership(
        address newOwner
    ) public virtual override {
        require(newOwner != address(0), "New owner is the zero address");
//        _revokeRole(DEFAULT_ADMIN_ROLE, owner());
//        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        super.transferOwnership(newOwner);
    }

    function _baseURI() internal view virtual  returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 rodType = rodTypes[tokenId];
        return string(abi.encodePacked(_baseTokenURI, rodType.toString(), ".json"));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function balanceOf(
        address owner
    ) public view virtual override returns (uint256) {
        return super.balanceOf(owner);
    }

    function tokenOfOwnerByIndex(
        address owner,
        uint256 index
    ) public view virtual override returns (uint256) {
        return super.tokenOfOwnerByIndex(owner, index);
    }

    function getOwnedTokenIds(
        address owner
    ) public view returns (uint256[] memory) {
        uint256 tokenCount = balanceOf(owner);
        uint256[] memory tokenIds = new uint256[](tokenCount);
        for (uint256 i = 0; i < tokenCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);
        }
        return tokenIds;
    }

    function _exists(uint256 tokenId) internal view returns (bool) {
        return true;
    }

    function _safeMint(
        address to,
        uint256 quantity,
        bytes memory _data
    ) internal {
//        uint256 startTokenId = currentIndex;
//        require(to != address(0), "ERC721A: mint to the zero address");
//        // We know if the first token in the batch doesn't exist, the other ones don't as well, because of serial ordering.
//        require(!_exists(startTokenId), "ERC721A: token already minted");
//        require(quantity <= maxBatchSize, "ERC721A: quantity to mint too high");
//
//        _beforeTokenTransfers(address(0), to, startTokenId, quantity);
//
//        AddressData memory addressData = _addressData[to];
//        _addressData[to] = AddressData(
//            addressData.balance + uint128(quantity),
//            addressData.numberMinted + uint128(quantity)
//        );
//        _ownerships[startTokenId] = TokenOwnership(to, uint64(block.timestamp));
//
//        uint256 updatedIndex = startTokenId;
//
//        for (uint256 i = 0; i < quantity; i++) {
//            emit Transfer(address(0), to, updatedIndex);
//            require(
//                _checkOnERC721Received(address(0), to, updatedIndex, _data),
//                "ERC721A: transfer to non ERC721Receiver implementer"
//            );
//            updatedIndex++;
//        }
//
//        currentIndex = updatedIndex;
//        _afterTokenTransfers(address(0), to, startTokenId, quantity);
    }

    /**
 * @dev See {IERC721-approve}.
   */
    function approve(address to, uint256 tokenId) public override {

    }

    /**
     * @dev See {IERC721-getApproved}.
   */
    function getApproved(uint256 tokenId) public view override returns (address) {

        return 0;
    }

    /**
     * @dev See {IERC721-setApprovalForAll}.
   */
    function setApprovalForAll(address operator, bool approved) public override {

    }

    /**
     * @dev See {IERC721-isApprovedForAll}.
   */
    function isApprovedForAll(address owner, address operator)
    public
    view
    virtual
    override
    returns (bool)
    {
        return true;
    }

    /**
     * @dev See {IERC721-transferFrom}.
   */
    function transferFrom(
        address from,
        address to,
        uint256 tokenId
    ) public override {
        _safeMint(from, to, tokenId);
    }

    function _transfer(
        address from,
        address to,
        uint256 tokenId
    ) private {
//        TokenOwnership memory prevOwnership = ownershipOf(tokenId);
//
//        bool isApprovedOrOwner = (_msgSender() == prevOwnership.addr ||
//        getApproved(tokenId) == _msgSender() ||
//            isApprovedForAll(prevOwnership.addr, _msgSender()));
//
//        require(
//            isApprovedOrOwner,
//            "ERC721A: transfer caller is not owner nor approved"
//        );
//
//        require(
//            prevOwnership.addr == from,
//            "ERC721A: transfer from incorrect owner"
//        );
//        require(to != address(0), "ERC721A: transfer to the zero address");
//
//        _beforeTokenTransfers(from, to, tokenId, 1);
//
//        // Clear approvals from the previous owner
//        _approve(address(0), tokenId, prevOwnership.addr);
//
//        _addressData[from].balance -= 1;
//        _addressData[to].balance += 1;
//        _ownerships[tokenId] = TokenOwnership(to, uint64(block.timestamp));
//
//        // If the ownership slot of tokenId+1 is not explicitly set, that means the transfer initiator owns it.
//        // Set the slot of tokenId+1 explicitly in storage to maintain correctness for ownerOf(tokenId+1) calls.
//        uint256 nextTokenId = tokenId + 1;
//        if (_ownerships[nextTokenId].addr == address(0)) {
//            if (_exists(nextTokenId)) {
//                _ownerships[nextTokenId] = TokenOwnership(
//                    prevOwnership.addr,
//                    prevOwnership.startTimestamp
//                );
//            }
//        }
//
//        emit Transfer(from, to, tokenId);
//        _afterTokenTransfers(from, to, tokenId, 1);
    }

    /**
 * @dev See {IERC721Metadata-name}.
     */
    function name() public view virtual override returns (string memory) {
        return _name;
    }

    /**
     * @dev See {IERC721Metadata-symbol}.
     */
    function symbol() public view virtual override returns (string memory) {
        return _symbol;
    }
}
