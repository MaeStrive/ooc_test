// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract FishingRodNFT is Ownable, ERC721, IERC721Enumerable, AccessControl, ERC721Holder
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    Counters.Counter private _tokenIds;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    mapping(uint256 => uint256) private _tokenByRodTypeIndex;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    string private _baseTokenURI = "ipfs://QmdfVNrqJ268FfmDB5c7TwZ41Wt3sf5kCESzbRZZdkefvJ/";

    uint256 public mintPrice;

    struct Listing {
        address seller;
        uint256 price;
    }

    struct RodNft {
        uint256 tokenId;
        uint256 rodType;
    }

    // Mapping from NFT contract address => (Token ID => Listing)
    mapping(uint256 => Listing) public listings;

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

    mapping(uint256 => uint256) private fishingRodTypes;


    event RodMinted(address indexed to, uint256 indexed tokenId, uint256 rodType);
    event RodAttributesUpdated(uint256 indexed tokenId);
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);
    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ItemSold(uint256 indexed tokenId, address indexed buyer, uint256 price);
    constructor(
        uint256 _mintPrice
    )ERC721("FishingRodNFT", "FRN")  {
        mintPrice = _mintPrice;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }



    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }


    function supportsInterface(bytes4 interfaceId) public view virtual override(ERC721, IERC165, AccessControl) returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            super.supportsInterface(interfaceId);
    }

    function mintRod() external payable returns (uint256, uint256) {
        require(msg.value >= mintPrice, "Insufficient payment");

        // Define probabilities for each rod type: 67%, 12%, 8%, 6%, 4%, 3%
        uint8[6] memory probabilities = [67, 12, 8, 6, 4, 3];

        // Sum of probabilities (100% = 67 + 12 + 8 + 6 + 4 + 3)
        uint256 totalProbability = 100;

        // Generate a random number in the range of 0 to totalProbability (0 to 100)
        uint256 randomNumber = uint256(keccak256(abi.encodePacked(
        block.timestamp,
        block.prevrandao,
        block.number,
        msg.sender,
        gasleft(),
        address(this).balance)))%totalProbability; // 合约余额也可以作为一个因素

        // Determine the rod type based on probabilities
        uint256 rodType = 0;
        uint256 cumulativeProbability = 0;
        for (uint256 i = 0; i < probabilities.length; i++) {
            cumulativeProbability += probabilities[i];
            if (randomNumber < cumulativeProbability) {
                rodType = i;
                break;
            }
        }

        // Mint the new rod and assign its type
        uint256 newRodTokenId = _tokenIds.current();
        _tokenIds.increment();
        fishingRodTypes[newRodTokenId] = rodType;
        _mint(msg.sender, newRodTokenId);
        _tokenByRodTypeIndex[newRodTokenId] = rodType;

        emit RodMinted(msg.sender, newRodTokenId, rodType);

        // Refund excess payment if over mintPrice
        if (msg.value > mintPrice) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }

        return (newRodTokenId, rodType);
    }


    function freeMintRod(address playAddress) external onlyAdmin returns (uint256, uint256) {
        uint256 rodType = 0;
        uint256 newRodTokenId = _tokenIds.current();
        _tokenIds.increment();
        fishingRodTypes[newRodTokenId] = rodType;
        _mint(playAddress, newRodTokenId);

        _tokenByRodTypeIndex[newRodTokenId] = rodType;

        emit RodMinted(playAddress, newRodTokenId, rodType);

        return (newRodTokenId, rodType);
    }

    function transferFrom(address from, address to, uint256 tokenId) public onlyAdmin override(ERC721, IERC721) {
        //solhint-disable-next-line max-line-length
        _transfer(from, to, tokenId);
    }


    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0), "Ownable: new owner is the zero address");
        _transferOwnership(newOwner);
    }

    function setBaseTokenURI(string memory newBaseTokenURI) external onlyAdmin {
        _baseTokenURI = newBaseTokenURI;
    }

    function setMintPrice(uint256 newMintPrice) external onlyAdmin {
        mintPrice = newMintPrice;
    }


    function _baseURI() internal view virtual override returns (string memory) {
        return _baseTokenURI;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        require(_exists(tokenId), "ERC721Metadata: URI query for nonexistent token");
        uint256 rodType = fishingRodTypes[tokenId];
        return string(abi.encodePacked(_baseTokenURI, rodType.toString(), ".json"));
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
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

    /**
 * @dev See {ERC721-_beforeTokenTransfer}.
     */
    function _beforeTokenTransfer(
        address from,
        address to,
        uint256 firstTokenId,
        uint256 batchSize
    ) internal virtual override {
        super._beforeTokenTransfer(from, to, firstTokenId, batchSize);

        if (batchSize > 1) {
            // Will only trigger during construction. Batch transferring (minting) is not available afterwards.
            revert("ERC721Enumerable: consecutive transfers not supported");
        }

        uint256 tokenId = firstTokenId;

        if (from == address(0)) {
            _addTokenToAllTokensEnumeration(tokenId);
        } else if (from != to) {
            _removeTokenFromOwnerEnumeration(from, tokenId);
        }
        if (to == address(0)) {
            _removeTokenFromAllTokensEnumeration(tokenId);
        } else if (to != from) {
            _addTokenToOwnerEnumeration(to, tokenId);
        }
    }

    /**
     * @dev Private function to add a token to this extension's ownership-tracking data structures.
     * @param to address representing the new owner of the given token ID
     * @param tokenId uint256 ID of the token to be added to the tokens list of the given address
     */
    function _addTokenToOwnerEnumeration(address to, uint256 tokenId) private {
        uint256 length = ERC721.balanceOf(to);
        _ownedTokens[to][length] = tokenId;
        _ownedTokensIndex[tokenId] = length;
    }

    /**
     * @dev Private function to add a token to this extension's token tracking data structures.
     * @param tokenId uint256 ID of the token to be added to the tokens list
     */
    function _addTokenToAllTokensEnumeration(uint256 tokenId) private {
        _allTokensIndex[tokenId] = _allTokens.length;
        _allTokens.push(tokenId);
    }

    /**
     * @dev Private function to remove a token from this extension's ownership-tracking data structures. Note that
     * while the token is not assigned a new owner, the `_ownedTokensIndex` mapping is _not_ updated: this allows for
     * gas optimizations e.g. when performing a transfer operation (avoiding double writes).
     * This has O(1) time complexity, but alters the order of the _ownedTokens array.
     * @param from address representing the previous owner of the given token ID
     * @param tokenId uint256 ID of the token to be removed from the tokens list of the given address
     */
    function _removeTokenFromOwnerEnumeration(address from, uint256 tokenId) private {
        // To prevent a gap in from's tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = ERC721.balanceOf(from) - 1;
        uint256 tokenIndex = _ownedTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary
        if (tokenIndex != lastTokenIndex) {
            uint256 lastTokenId = _ownedTokens[from][lastTokenIndex];

            _ownedTokens[from][tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
            _ownedTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index
        }

        // This also deletes the contents at the last position of the array
        delete _ownedTokensIndex[tokenId];
        delete _ownedTokens[from][lastTokenIndex];
    }

    /**
     * @dev Private function to remove a token from this extension's token tracking data structures.
     * This has O(1) time complexity, but alters the order of the _allTokens array.
     * @param tokenId uint256 ID of the token to be removed from the tokens list
     */
    function _removeTokenFromAllTokensEnumeration(uint256 tokenId) private {
        // To prevent a gap in the tokens array, we store the last token in the index of the token to delete, and
        // then delete the last slot (swap and pop).

        uint256 lastTokenIndex = _allTokens.length - 1;
        uint256 tokenIndex = _allTokensIndex[tokenId];

        // When the token to delete is the last token, the swap operation is unnecessary. However, since this occurs so
        // rarely (when the last minted token is burnt) that we still do the swap here to avoid the gas cost of adding
        // an 'if' statement (like in _removeTokenFromOwnerEnumeration)
        uint256 lastTokenId = _allTokens[lastTokenIndex];

        _allTokens[tokenIndex] = lastTokenId; // Move the last token to the slot of the to-delete token
        _allTokensIndex[lastTokenId] = tokenIndex; // Update the moved token's index

        // This also deletes the contents at the last position of the array
        delete _allTokensIndex[tokenId];
        _allTokens.pop();
    }

    function tokenOfOwnerByIndex(address owner, uint256 index) public view virtual override returns (uint256) {
        require(index < ERC721.balanceOf(owner), "ERC721Enumerable: owner index out of bounds");
        return _ownedTokens[owner][index];
    }

    /**
     * @dev See {IERC721Enumerable-totalSupply}.
     */
    function totalSupply() public view virtual override returns (uint256) {
        return _allTokens.length;

    }

    /**
     * @dev See {IERC721Enumerable-tokenByIndex}.
     */
    function tokenByIndex(uint256 index) public view virtual override returns (uint256) {
        require(index < totalSupply(), "ERC721Enumerable: global index out of bounds");
        return _allTokens[index];
    }

    function listItem(uint256 tokenId, uint256 price) external {
        // 确保价格大于0
        require(price > 0, "Price must be greater than zero");

        // 确保调用者是NFT的所有者
        require(ERC721.ownerOf(tokenId) == msg.sender, "You are not the owner of this NFT");

        // 将NFT从卖家转移到合约本身进行托管
        ERC721.transferFrom(msg.sender, address(this), tokenId);

        // 创建上架信息
        listings[tokenId] = Listing({
            seller: msg.sender,
            price: price
        });

        emit ItemListed(tokenId, msg.sender, price);
    }

    function buyItem(uint256 tokenId) external payable {
        // 获取NFT上架信息
        Listing memory listing = listings[tokenId];

        // 确保该NFT已上架
        require(listing.price > 0, "This NFT is not for sale");

        // 确保买家支付的金额足够
        require(msg.value == listing.price, "Incorrect price");

        // 删除上架信息
        delete listings[tokenId];

        // 将NFT转移给买家
        ERC721.transferFrom(address(this), msg.sender, tokenId);

        // 支付给卖家
        payable(listing.seller).transfer(msg.value);

        emit ItemSold(tokenId, msg.sender, listing.price);
    }

    function cancelListing(uint256 tokenId) external {
        // 确保调用者是NFT的卖家
        Listing memory listing = listings[tokenId];
        require(listing.seller == msg.sender, "You are not the seller");

        // 删除上架信息
        delete listings[tokenId];

        // 将NFT返还给卖家
        ERC721.transferFrom(address(this), msg.sender, tokenId);
    }


    function getOwnedNFTs(address owner) external view returns (RodNft[] memory) {
        uint256 nftCount = balanceOf(owner);  // 获取该地址拥有的NFT数量

        uint256[] memory tokenIds = new uint256[](nftCount);  // 创建数组来存储Token ID
        uint256[] memory rodTypes = new uint256[](nftCount);  // 创建数组来存储Token ID

        for (uint256 i = 0; i < nftCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);  // 遍历获取每个NFT的Token ID
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            rodTypes[i] = getRodTypeByTokenId(tokenIds[i]);  // 遍历获取每个NFT的Token ID
        }

        RodNft[] memory rodNftInfo = new RodNft[](nftCount);
        for (uint256 i = 0; i < nftCount; i++) {
            RodNft memory rodInfo = RodNft({
                tokenId: tokenIds[i],
                rodType: rodTypes[i]
            });
            rodNftInfo[i] = rodInfo;
        }
        return rodNftInfo;  // 返回所有NFT的Token ID
    }

    function getRodTypeByTokenId(uint256 tokenId) public view virtual returns (uint256){
        return _tokenByRodTypeIndex[tokenId];
    }


}
