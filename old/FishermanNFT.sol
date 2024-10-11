// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721Enumerable.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract FishermanNFT is ERC721Enumerable, Ownable, AccessControl {
    using Counters for Counters.Counter;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    Counters.Counter private _tokenIds;

    uint256 public mintPrice;
    uint256 public maxSupply;
    string private _baseTokenURI;

    struct FishermanAttributes {
        uint256 level;
        uint256 experience;
        uint256 strength;
        uint256 dexterity;
        uint256 intelligence;
        uint256 luck;
        uint256 tokenId;
        string imageURI;
    }

    mapping(uint256 => FishermanAttributes) private _fishermanAttributes;

    uint256 public transferFee; // 添加转移费用变量

    event FishermanMinted(address indexed to, uint256 indexed tokenId);
    event FishermanAttributesUpdated(uint256 indexed tokenId);
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);

    constructor(
        string memory name,
        string memory symbol,
        uint256 _mintPrice,
        uint256 _maxSupply,
        uint256 _transferFee // 添加转移费用参数
    ) ERC721(name, symbol) {
        mintPrice = _mintPrice;
        maxSupply = _maxSupply;
        transferFee = _transferFee; // 设置转移费用
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(ERC721Enumerable, AccessControl)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    function mintFisherman() external payable returns (uint256) {
        require(msg.value >= mintPrice, "Insufficient payment");
        require(_tokenIds.current() < maxSupply, "Max supply reached");

        _tokenIds.increment();
        uint256 newFishermanId = _tokenIds.current();
        _safeMint(msg.sender, newFishermanId);

        emit FishermanMinted(msg.sender, newFishermanId);

        if (msg.value > mintPrice) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }

        return newFishermanId;
    }

    function tokenURI(uint256 tokenId)
    public
    view
    virtual
    override
    returns (string memory)
    {
        require(
            _exists(tokenId),
            "ERC721Metadata: URI query for nonexistent token"
        );

        string memory baseURI = _baseURI();
        return
            bytes(baseURI).length > 0
                ? string(abi.encodePacked(baseURI, tokenId.toString(),".json"))
                : "";
    }

    function getFishermanAttributes(
        uint256 tokenId
    ) external view returns (FishermanAttributes memory) {
        require(_exists(tokenId), "Fisherman does not exist");
        return _fishermanAttributes[tokenId];
    }

    function updateFishermanAttributes(
        uint256 tokenId,
        FishermanAttributes memory newAttributes
    ) external onlyAdmin {
        require(_exists(tokenId), "Fisherman does not exist");
        _fishermanAttributes[tokenId] = newAttributes;
        emit FishermanAttributesUpdated(tokenId);
    }

    function setMintPrice(uint256 newMintPrice) external onlyAdmin {
        mintPrice = newMintPrice;
    }

    function setMaxSupply(uint256 newMaxSupply) external onlyAdmin {
        require(
            newMaxSupply >= _tokenIds.current(),
            "New max supply must be greater than or equal to current supply"
        );
        maxSupply = newMaxSupply;
    }

    function setBaseURI(string memory newBaseURI) external onlyAdmin {
        _baseTokenURI = newBaseURI;
    }

    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function addAdmin(address newAdmin) external onlyOwner {
        grantRole(ADMIN_ROLE, newAdmin);
        emit AdminAdded(newAdmin);
    }

    function removeAdmin(address admin) external onlyOwner {
        revokeRole(ADMIN_ROLE, admin);
        emit AdminRemoved(admin);
    }

    function transferFisherman(address to, uint256 tokenId) external payable {
        require(msg.value >= transferFee, "Insufficient transfer fee");
        require(
            _isApprovedOrOwner(_msgSender(), tokenId),
            "Caller is not owner nor approved"
        );

        _transfer(_msgSender(), to, tokenId);

        // 退还多余的ETH
        if (msg.value > transferFee) {
            payable(_msgSender()).transfer(msg.value - transferFee);
        }
    }

    function setTransferFee(uint256 newTransferFee) external onlyAdmin {
        transferFee = newTransferFee;
    }

    function transferOwnership(
        address newOwner
    ) public virtual override onlyOwner {
        require(newOwner != address(0), "New owner is the zero address");
        _revokeRole(DEFAULT_ADMIN_ROLE, owner());
        _grantRole(DEFAULT_ADMIN_ROLE, newOwner);
        super.transferOwnership(newOwner);
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
}
