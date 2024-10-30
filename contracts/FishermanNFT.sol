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


    mapping(uint256 => string) private _tokenByFishermanTypeIndex;

    // Array with all token ids, used for enumeration
    uint256[] private _allTokens;

    // Mapping from token id to position in the allTokens array
    mapping(uint256 => uint256) private _allTokensIndex;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // 新增 mapping 记录已铸造的图片 URI
    mapping(string => bool) private mintedURIs;

    string private _baseTokenURI = "ipfs://QmQ3DbbCuPH5cVFn4d6CeyAMLmwzTjNNtRt8nuaEBroFJj/";
    uint256 public mintPrice;

    struct Listing {
        address seller;
        uint256 price;
    }
    // Mapping from NFT contract address => (Token ID => Listing)
    mapping(uint256 => Listing) public listings;

    struct FishermanNft {
        uint256 tokenId;
        string fishermanType;
    }


    uint256[] public maxSupplies;
    uint256[] public mintedSupplies;

    // 定义状态变量，用于存储每种类型的部位选项
    uint8[9] public partOptions0 = [1, 1, 9, 9, 9, 9, 9, 9, 9]; // 类型 0 的部位选项
    uint8[9] public partOptions1 = [1, 1, 4, 4, 4, 4, 4, 4, 4]; // 类型 1 的部位选项
    uint8[9] public partOptions2 = [1, 1, 3, 3, 3, 3, 3, 3, 3]; // 类型 2 的部位选项


    event FishermanMinted(address indexed to, uint256 indexed tokenId, string fishermanType);
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
        maxSupplies = [4782969, 16384, 2187];  // 初始值
        mintedSupplies = new uint256[](maxSupplies.length);  // 初始化 mintedSupplies 数组大小与 maxSupplies 一致
    }



    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "301");
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

        if (randomNumber <= 49) {
            fishermanType = 1;
        }
        else if (randomNumber <= 50) {
            fishermanType = 1;
        }
        else {
            fishermanType = 2;
        }

        require(mintedSupplies[fishermanType] < maxSupplies[fishermanType], "106");

        uint256 newFishermanTokenId = _tokenIds.current(); // 获取当前递增的 token ID
        _tokenIds.increment(); // 递增 token ID

        // 根据 fishermanType 定义每个部位的选项数量
        uint8[9] memory partOptions;

        if (fishermanType == 0) {
            partOptions = partOptions0;
        } else if (fishermanType == 1) {
            partOptions = partOptions1;
        } else {
            partOptions = partOptions2;
        }
        string memory partIdString;

        bool uniqueIdFound = false;
        while (!uniqueIdFound) {
            // 随机生成每个部位的 ID
            uint8[9] memory partIds; // 8 个部位
            partIds[0] = uint8(fishermanType + 1);
            for (uint8 i = 1; i < partIds.length; i++) {
                partIds[i] = uint8(random() % partOptions[i] + 1); // 随机生成部位 ID
            }
            // 构建部位 ID 字符串
            partIdString = string(abi.encodePacked(
                uintToString(partIds[0]),
                uintToString(partIds[1]),
                uintToString(partIds[2]),
                uintToString(partIds[3]),
                uintToString(partIds[4]),
                uintToString(partIds[5]),
                uintToString(partIds[6]),
                uintToString(partIds[7]),
                uintToString(partIds[8])));
            // 检查该 URI 是否已经铸造
            if (!mintedURIs[partIdString]) {
                uniqueIdFound = true; // 找到未被铸造的 ID
            }
        }
        // 增加该类型的已 mint 数量
        mintedSupplies[fishermanType]++;

        _mint(msg.sender, newFishermanTokenId);

        // 可以在这里设置 CID 对应的 metadata 或者 tokenURI
        setTokenURI(newFishermanTokenId, partIdString);
        _tokenByFishermanTypeIndex[newFishermanTokenId] = partIdString;
        // 标记该 URI 已铸造
        mintedURIs[partIdString] = true;
        emit FishermanMinted(msg.sender, newFishermanTokenId, partIdString);
        if (msg.value > mintPrice) {
            payable(msg.sender).transfer(msg.value - mintPrice);
        }
        return newFishermanTokenId;
    }

//    function freeMintFisherman(address playAddress) external onlyAdmin returns (uint256) {
//        uint256 fishermanType = 0;
//        require(mintedSupplies[fishermanType] < maxSupplies[fishermanType], "106");
//
//        uint256 newFishermanTokenId = _tokenIds.current(); // 获取当前递增的 token ID
//        _tokenIds.increment(); // 递增 token ID
//
//        // 根据 fishermanType 定义每个部位的选项数量
//        uint8[9] memory partOptions;
//        partOptions = partOptions0;
//
//        string memory partIdString;
//
//        bool uniqueIdFound = false;
//        while (!uniqueIdFound) {
//            // 随机生成每个部位的 ID
//            uint8[9] memory partIds; // 8 个部位
//            partIds[0] = uint8(fishermanType + 1);
//            for (uint8 i = 1; i < partIds.length; i++) {
//                partIds[i] = uint8(random() % partOptions[i] + 1); // 随机生成部位 ID
//            }
//            // 构建部位 ID 字符串
//            partIdString = string(abi.encodePacked(
//                uintToString(partIds[0]),
//                uintToString(partIds[1]),
//                uintToString(partIds[2]),
//                uintToString(partIds[3]),
//                uintToString(partIds[4]),
//                uintToString(partIds[5]),
//                uintToString(partIds[6]),
//                uintToString(partIds[7]),
//                uintToString(partIds[8])));
//            // 检查该 URI 是否已经铸造
//            if (!mintedURIs[partIdString]) {
//                uniqueIdFound = true; // 找到未被铸造的 ID
//            }
//        }
//        // 增加该类型的已 mint 数量
//        mintedSupplies[fishermanType]++;
//
//        _mint(playAddress, newFishermanTokenId);
//
//        // 可以在这里设置 CID 对应的 metadata 或者 tokenURI
//        setTokenURI(newFishermanTokenId, partIdString);
//        _tokenByFishermanTypeIndex[newFishermanTokenId] = partIdString;
//        // 标记该 URI 已铸造
//        mintedURIs[partIdString] = true;
//        return newFishermanTokenId;
//    }

    function transferFrom(address from, address to, uint256 tokenId) public onlyAdmin override(ERC721, IERC721) {
        //solhint-disable-next-line max-line-length
        _transfer(from, to, tokenId);
    }


    function transferOwnership(address newOwner) public virtual override onlyOwner {
        require(newOwner != address(0));
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
        require(_exists(tokenId));
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

    function setTokenURI(uint256 tokenId, string memory tokenCID) internal virtual {
        require(_exists(tokenId));
        _tokenURIs[tokenId] = string(abi.encodePacked(_baseTokenURI, tokenCID, ".json"));
        emit MetadataUpdate(tokenId);
    }

    function withdraw() external onlyOwner {
        uint256 balance = address(this).balance;
        payable(owner()).transfer(balance);
    }

    function uintToString(uint8 value) internal pure returns (string memory) {
        if (value < 10) {
            // 如果是单数字，则前面加0
            return string(abi.encodePacked("0", uint2str(value)));
        } else {
            return uint2str(value);
        }
    }

    function uint2str(uint8 _i) internal pure returns (string memory _uintAsString) {
        if (_i == 0) {
            return "0";
        }
        uint8 temp = _i;
        uint8 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory bstr = new bytes(digits);
        uint8 k = digits;
        while (_i != 0) {
            bstr[--k] = bytes1(uint8(48 + _i % 10));
            _i /= 10;
        }
        return string(bstr);
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
        require(index < ERC721.balanceOf(owner), "1");
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
        require(index < totalSupply());
        return _allTokens[index];
    }

    function listItem(uint256 tokenId, uint256 price) external {
        // 确保价格大于0
        require(price > 0);

        // 确保调用者是NFT的所有者
        require(ERC721.ownerOf(tokenId) == msg.sender);

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
        require(listing.price > 0, "107");

        // 确保买家支付的金额足够
        require(msg.value == listing.price, "108");

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
        require(listing.seller == msg.sender, "105");

        // 删除上架信息
        delete listings[tokenId];

        // 将NFT返还给卖家
        ERC721.transferFrom(address(this), msg.sender, tokenId);
    }


    function random() private view returns (uint256) {
        // 结合更多因素以增加随机性
        return uint256(keccak256(abi.encodePacked(
            block.timestamp,
            block.prevrandao,
            block.number,
            msg.sender,
            gasleft(),
            address(this).balance // 合约余额也可以作为一个因素
        )));
    }

    // 查询某地址拥有的所有NFT
    function getOwnedNFTs(address owner) external view returns (FishermanNft[] memory) {
        uint256 nftCount = balanceOf(owner);  // 获取该地址拥有的NFT数量

        uint256[] memory tokenIds = new uint256[](nftCount);  // 创建数组来存储Token ID
        string[] memory fishermanTypes = new string[](nftCount);  // 创建数组来存储Token ID
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
        require(newMaxSupplies.length >= mintedSupplies.length);
        for (uint256 i = 0; i < newMaxSupplies.length; i++) {
            if (i < mintedSupplies.length) {
                require(newMaxSupplies[i] >= mintedSupplies[i]);
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
        require(index < maxSupplies.length);
        require(newMaxSupply >= mintedSupplies[index]);
        maxSupplies[index] = newMaxSupply;
    }

    function getFishermanTypeByTokenId(uint256 tokenId) public view virtual returns (string memory){
        return _tokenByFishermanTypeIndex[tokenId];
    }
    // 定义一个函数来更新部位选项
    function setPartOptions(uint256 typeIndex, uint8[9] memory newOptions) external onlyAdmin {
        require(typeIndex < 3); // 确保类型索引有效

        if (typeIndex == 0) {
            partOptions0 = newOptions; // 更新类型 0 的部位选项
        } else if (typeIndex == 1) {
            partOptions1 = newOptions; // 更新类型 1 的部位选项
        } else {
            partOptions2 = newOptions; // 更新类型 2 的部位选项
        }
    }
}
