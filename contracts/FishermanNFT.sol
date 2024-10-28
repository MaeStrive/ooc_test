// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "./ERC721.sol";
import "./IERC721Enumerable.sol";
import "@openzeppelin/contracts/token/ERC721/utils/ERC721Holder.sol";

contract FishermanNFT is Ownable, ERC721, IERC721Enumerable, AccessControl, ERC721Holder
{
    using Counters for Counters.Counter;
    using Strings for uint256;

    // Token name
    string private _name;

    // Token symbol
    string private _symbol;
    Counters.Counter private _tokenIds;
    mapping(uint256 => string) private _tokenURIs;

    // Mapping from owner to list of owned token IDs
    mapping(address => mapping(uint256 => uint256)) private _ownedTokens;

    // Mapping from token ID to index of the owner tokens list
    mapping(uint256 => uint256) private _ownedTokensIndex;


    mapping(uint256 => uint256) private _tokenByFishermanTypeIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    string private _baseTokenURI = "ipfs://QmRyTJ6mtC4mNFhZRcqHd3R2QLnKA1XLxffU8nXSfxiZKW/";
    uint256 public mintPrice;

    struct Listing {
        address seller;
        uint256 price;
    }
    // Mapping from NFT contract address => (Token ID => Listing)
    mapping(uint256 => Listing) public listings;

    struct FishermanNft {
        uint256 tokenId;
        uint256 fishermanType;
    }


    uint256[] public maxSupplies;
    uint256[] public mintedSupplies;


    event FishermanMinted(address indexed to, uint256 indexed tokenId, uint256 fishermanType);
    event AdminAdded(address indexed newAdmin);
    event AdminRemoved(address indexed removedAdmin);
    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ItemSold(uint256 indexed tokenId, address indexed buyer, uint256 price);
    event MetadataUpdate(uint256 _tokenId);


    constructor(
        uint256 _mintPrice
    )ERC721("FishermanNFT", "FMN")  {
        mintPrice = _mintPrice;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        maxSupplies = [4723920, 16384, 2187];  // 初始值
        mintedSupplies = new uint256[](maxSupplies.length);  // 初始化 mintedSupplies 数组大小与 maxSupplies 一致
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

    function mintFisherman() external payable returns (uint256) {
        require(msg.value >= mintPrice, "Insufficient payment");

        uint256 randomNumber = random() % 100 + 1;
        uint256 fishermanType = 0;

        if (randomNumber <= 70) {
            fishermanType = 0;
        }
        else if (randomNumber <= 99) {
            fishermanType = 1;
        }
        else {
            fishermanType = 2;
        }

        require(mintedSupplies[fishermanType] < maxSupplies[fishermanType], "Max supply reached for this type");

        uint256 newFishermanTokenId = _tokenIds.current(); // 获取当前递增的 token ID
        _tokenIds.increment(); // 递增 token ID

        // 根据 fishermanType 选择图片的 CID 区间
        uint256 tokenCID;
        if (fishermanType == 0) {
            tokenCID = mintedSupplies[fishermanType]; // 分配低品质的 CID （0 到 79999）
        } else if (fishermanType == 1) {
            tokenCID = mintedSupplies[fishermanType] + maxSupplies[0]; // 分配中品质的 CID （80000 到 94999）
        } else {
            tokenCID = mintedSupplies[fishermanType] + maxSupplies[0] + maxSupplies[1]; // 分配高品质的 CID （95000 到 99999）
        }

        // 增加该类型的已 mint 数量
        mintedSupplies[fishermanType]++;

        _mint(msg.sender, newFishermanTokenId);

        // 可以在这里设置 CID 对应的 metadata 或者 tokenURI
        setTokenURI(newFishermanTokenId, tokenCID);
        _tokenByFishermanTypeIndex[newFishermanTokenId] = tokenCID;
        emit FishermanMinted(msg.sender, newFishermanTokenId, fishermanType);
        if (msg.value > mintPrice) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }
        return newFishermanTokenId;
    }

    function freeMintFisherman(address playAddress) external onlyAdmin returns (uint256) {
        uint256 fishermanType = 0;

        require(mintedSupplies[fishermanType] < maxSupplies[fishermanType], "Max supply reached for this type");

        uint256 newFishermanTokenId = _tokenIds.current(); // 获取当前递增的 token ID
        _tokenIds.increment(); // 递增 token ID

        // 根据 fishermanType 选择图片的 CID 区间
        uint256 tokenCID;
        if (fishermanType == 0) {
            tokenCID = mintedSupplies[fishermanType]; // 分配低品质的 CID （0 到 79999）
        } else if (fishermanType == 1) {
            tokenCID = mintedSupplies[fishermanType] + maxSupplies[0]; // 分配中品质的 CID （80000 到 94999）
        } else {
            tokenCID = mintedSupplies[fishermanType] + maxSupplies[0] + maxSupplies[1]; // 分配高品质的 CID （95000 到 99999）
        }

        // 增加该类型的已 mint 数量
        mintedSupplies[fishermanType]++;
        // 可以在这里设置 CID 对应的 metadata 或者 tokenURI
        _mint(playAddress, newFishermanTokenId);
        setTokenURI(newFishermanTokenId, tokenCID);
        _tokenByFishermanTypeIndex[newFishermanTokenId] = tokenCID;

        emit FishermanMinted(msg.sender, newFishermanTokenId, fishermanType);
        return newFishermanTokenId;
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
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return _tokenURI;
        }

        return super.tokenURI(tokenId);
    }

    function setTokenURI(uint256 tokenId, uint256 tokenCID) internal virtual {
        require(_exists(tokenId), "FMN: URI set of nonexistent token");
        _tokenURIs[tokenId] = string(abi.encodePacked(_baseTokenURI, tokenCID.toString(), ".json"));
        emit MetadataUpdate(tokenId);
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


    function random() private view returns (uint256) {
        return uint256(keccak256(abi.encodePacked(block.timestamp, block.prevrandao, msg.sender)));
    }

    // 查询某地址拥有的所有NFT
    function getOwnedNFTs(address owner) external view returns (FishermanNft[] memory) {
        uint256 nftCount = balanceOf(owner);  // 获取该地址拥有的NFT数量

        uint256[] memory tokenIds = new uint256[](nftCount);  // 创建数组来存储Token ID
        uint256[] memory fishermanTypes = new uint256[](nftCount);  // 创建数组来存储Token ID
        for (uint256 i = 0; i < nftCount; i++) {
            tokenIds[i] = tokenOfOwnerByIndex(owner, i);  // 遍历获取每个NFT的Token ID
        }
        for (uint256 i = 0; i < tokenIds.length; i++) {
            fishermanTypes[i] = getFishermanTypeByTokenId(tokenIds[i]);  // 遍历获取每个NFT的Token ID
        }
        FishermanNft[] memory fishermanInfos = new FishermanNft[](nftCount);
        for (uint256 i = 0; i < nftCount; i++) {
            FishermanNft memory fishermanInfo = FishermanNft({
                tokenId: tokenIds[i],
                fishermanType: fishermanTypes[i]
            });
            fishermanInfos[i] = fishermanInfo;
        }
        return fishermanInfos;  // 返回所有NFT的Token ID

    }

    // 修改整个数组的内容和大小
    function setMaxSupplies(uint256[] memory newMaxSupplies) public onlyAdmin {
        require(newMaxSupplies.length >= mintedSupplies.length, "New array cannot be shorter than mintedSupplies");
        for (uint256 i = 0; i < newMaxSupplies.length; i++) {
            if (i < mintedSupplies.length) {
                require(newMaxSupplies[i] >= mintedSupplies[i], "New max supply must be greater than or equal to minted supply");
            }
        }
        maxSupplies = newMaxSupplies;
        // 如果新数组比 mintedSupplies 长，则扩展 mintedSupplies
        if (newMaxSupplies.length > mintedSupplies.length) {
            for (uint256 i = mintedSupplies.length; i < newMaxSupplies.length; i++) {
                mintedSupplies.push(0);  // 填充新的mintedSupplies元素为 0
            }
        }
    }

    // 修改数组的特定索引值
    function updateMaxSupplyAt(uint256 index, uint256 newMaxSupply) public onlyAdmin {
        require(index < maxSupplies.length, "Index out of bounds");
        require(newMaxSupply >= mintedSupplies[index], "New max supply must be greater than or equal to minted supply");
        maxSupplies[index] = newMaxSupply;
    }

    function getFishermanTypeByTokenId(uint256 tokenId) public view virtual returns (uint256){
        return _tokenByFishermanTypeIndex[tokenId];
    }

}
