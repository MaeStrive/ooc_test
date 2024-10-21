// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

// 引入GMC合约的接口
interface IGMC {
    function mint(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address sender, address recipient, uint256 amount) external;

}

interface IFishermanNFT {
    function ownerOf(uint256 tokenId) external view returns (address);

    function getOwnedNFTs(address owner) external view returns (uint256[] memory);
}

interface IFishingRodNFT {
    function ownerOf(uint256 tokenId) external view returns (address);

    function getRodTypeByTokenId(uint256 tokenId) external view returns (uint256);

    function getOwnedNFTs(address owner) external view returns (uint256[] memory);
}


contract User is Ownable, AccessControl {

    IGMC public gmcContract;  // 添加GMC合约的地址
    IFishermanNFT public fishermanNFT;
    IFishingRodNFT public fishingRodNFT;

    struct PlayerInfo {
        uint256 fishingCount;
        uint256 experience;
        uint256 level;
        uint256[5] unlockedFishingSpots;
        uint256 currentFishingSpot;
        uint256 fishPoolLevel;
        uint256 interestRate;
        uint256 collectedGMC;
        uint256 baitCount;
        uint256[10] fishCount;
        uint256 currentFishermanNFT;
        uint256 currentRodNFT;
    }

    address private _pendingOwner;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public levelUpLimit;
    uint256 public baitPurchaseLimit;
    uint256 public fishingCountLimit;
    uint256 public baitPrice;

    mapping(address => PlayerInfo) private players;
    mapping(address => bool) private registeredPlayers;

    event PlayerAdded(address indexed playerAddress);
    event PlayerLeveledUp(address indexed playerAddress, uint256 newLevel);
    event ExperienceAdded(
        address indexed playerAddress,
        uint256 addedExp,
        uint256 newExp
    );
    event FishermanChanged(
        address indexed playerAddress,
        uint256 newFishermanId
    );
    event RodChanged(address indexed playerAddress, uint256 newRodId);
    event UserDataUpdate(PlayerInfo[] indexed playerInfo, address[] indexed playerAddresses);

    event PlayerLevelUpdated(address indexed playerAddress, uint256 newLevel);
    event FishPoolLevelUpdated(address indexed playerAddress, uint256 newLevel);
    event FishCountUpdated(
        address indexed playerAddress,
        uint256 star,
        uint256 newCount
    );
    event CollectedGMCUpdated(address indexed playerAddress, uint256 newAmount);
    event BaitCountUpdated(address indexed playerAddress, uint256 newCount);
    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );
    event LimitAttributeUpdate(uint256 indexed levelUpLimit, uint256 indexed baitPurchaseLimit, uint256 indexed baitPrice);

    event ClaimGMC(address userAddress, uint256 count);
    constructor(address _gmcContract, address _fishermanNFT, address _fishingRodNFT, uint256 _baitPrice) {
        levelUpLimit = 51; // 设置默认等级上限
        baitPurchaseLimit = 99; // 设置默认鱼饵购买上限
        fishingCountLimit = 10; // 设置默认钓鱼次数上限
        baitPrice = _baitPrice;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        gmcContract = IGMC(_gmcContract);  // 初始化GMC合约的地址
        fishermanNFT = IFishermanNFT(_fishermanNFT);
        fishingRodNFT = IFishingRodNFT(_fishingRodNFT);
    }

    modifier onlyRegisteredPlayer() {
        require(registeredPlayers[msg.sender]);
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender));
        _;
    }

    function addAdmin(address newAdmin) external onlyOwner {
        grantRole(ADMIN_ROLE, newAdmin);
    }

    function removeAdmin(address admin) external onlyOwner {
        revokeRole(ADMIN_ROLE, admin);
    }

    function transferOwnership(
        address newOwner
    ) public virtual override onlyOwner {
        require(newOwner != address(0));
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    function acceptOwnership() public virtual {
        require(msg.sender == _pendingOwner);
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    function addUser(address userAddress) external onlyAdmin {
        require(!registeredPlayers[userAddress]);

        players[userAddress] = PlayerInfo({
            fishingCount: 10,
            experience: 0,
            level: 1,
            currentFishermanNFT: type(uint256).max,
            currentRodNFT: type(uint256).max,
            currentFishingSpot: 0,
            fishPoolLevel: 1,
            fishCount: [uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0), uint256(0)],
            unlockedFishingSpots: [1001, uint256(0), uint256(0), uint256(0), uint256(0)],
            interestRate: 0,
            collectedGMC: 0,
            baitCount: 30
        });
        registeredPlayers[userAddress] = true;
        emit PlayerAdded(userAddress);
    }

    function getUser(
        address userAddress
    ) external view onlyAdmin returns (PlayerInfo memory) {
        require(registeredPlayers[userAddress]);
        return players[userAddress];
    }

    function setFishingCount(
        address userAddress,
        uint256 count
    ) external onlyAdmin {
        require(registeredPlayers[userAddress]);
        players[userAddress].fishingCount = count;
    }


    function setExperience(
        address userAddress,
        uint256 exp
    ) external onlyAdmin {
        require(registeredPlayers[userAddress], "101");
        PlayerInfo storage player = players[userAddress];
        player.experience = exp;
        emit ExperienceAdded(userAddress, exp, player.experience);
    }

    function changeFisherman(
        address userAddress,
        uint256 fishermanId
    ) external onlyAdmin {
        require(registeredPlayers[userAddress], "101");
        uint256 realFishermanId;
        // Check ownership
        uint256[] memory fishermanIds;
        if (fishermanNFT.ownerOf(fishermanId) != userAddress) {
            // Randomly select an NFT
            fishermanIds = fishermanNFT.getOwnedNFTs(userAddress);
            if (fishermanIds.length > 0) {
                realFishermanId = fishermanIds[0];
                players[userAddress].currentFishermanNFT = realFishermanId;
            } else {
                realFishermanId = type(uint256).max;
            }
        } else {
            players[userAddress].currentFishermanNFT = fishermanId;
            realFishermanId = fishermanId;
        }
        emit FishermanChanged(userAddress, realFishermanId);
    }

    function getCurrentFishermanNFT(
        address playerAddress
    ) external view returns (uint256) {
        require(registeredPlayers[playerAddress], "101");
        return players[playerAddress].currentFishermanNFT;
    }


    function changeRod(uint256 rodId, address userAddress) external onlyAdmin {
        require(registeredPlayers[userAddress], "101");
        uint256 realFishingRodId;
        uint256[] memory fishingRodIds;
        // Check ownership
        if (fishingRodNFT.ownerOf(rodId) != userAddress) {
            // Randomly select an NFT
            fishingRodIds = fishingRodNFT.getOwnedNFTs(userAddress);
            if (fishingRodIds.length > 0) {
                realFishingRodId = fishingRodIds[0];
                players[userAddress].currentRodNFT = realFishingRodId;
            } else {
                realFishingRodId = type(uint256).max;
            }
        } else {
            players[userAddress].currentRodNFT = rodId;
            realFishingRodId = rodId;
        }
        emit RodChanged(userAddress, realFishingRodId);
    }

    function getCurrentFishingRodNFT(
        address playerAddress
    ) external view returns (uint256) {
        require(registeredPlayers[playerAddress], "101");
        return players[playerAddress].currentRodNFT;
    }


    function getUnlockedFishingSpots(
        address userAddress
    ) external view returns (uint256[5] memory) {
        require(registeredPlayers[userAddress], "101");
        return players[userAddress].unlockedFishingSpots;
    }


    function getLevelUpLimit() external view returns (uint256) {
        return levelUpLimit;
    }


    function setLevelUpLimit(uint256 _levelUpLimit) external onlyAdmin {
        levelUpLimit = _levelUpLimit;
    }


    function setBaitPurchaseLimit(
        uint256 _baitPurchaseLimit
    ) external onlyAdmin {
        baitPurchaseLimit = _baitPurchaseLimit;
    }

    function setFishingCountLimit(
        uint256 _fishingCountLimit
    ) external onlyAdmin {
        fishingCountLimit = _fishingCountLimit;
    }

    function getBaitPurchaseLimit() external view returns (uint256) {
        return baitPurchaseLimit;
    }

    function getFishingCountLimit() external view returns (uint256) {
        return fishingCountLimit;
    }

    function getPlayerLevel(
        address playerAddress
    ) external view returns (uint256) {
        require(registeredPlayers[playerAddress], "101");
        return players[playerAddress].level;
    }

    function setPlayerLevel(
        address playerAddress,
        uint256 newLevel
    ) external onlyAdmin {
        require(registeredPlayers[playerAddress], "101");
        players[playerAddress].level = newLevel;
        emit PlayerLevelUpdated(playerAddress, newLevel);
    }

    function getFishPoolLevel(
        address playerAddress
    ) external view returns (uint256) {
        require(registeredPlayers[playerAddress], "101");
        return players[playerAddress].fishPoolLevel;
    }

    function setFishPoolLevel(
        address playerAddress,
        uint256 newLevel
    ) external onlyAdmin {
        require(registeredPlayers[playerAddress], "101");
        players[playerAddress].fishPoolLevel = newLevel;
        emit FishPoolLevelUpdated(playerAddress, newLevel);
    }

    function getFishCount(
        address playerAddress
    ) external view returns (uint256[10] memory) {
        require(registeredPlayers[playerAddress], "101");
        return players[playerAddress].fishCount;
    }

    function getExperience(
        address playerAddress
    ) external view returns (uint256) {
        require(registeredPlayers[playerAddress], "101");
        return players[playerAddress].experience;
    }

    function setFishCount(
        address playerAddress,
        uint256 star,
        uint256 newCount
    ) external onlyAdmin {
        require(registeredPlayers[playerAddress], "101");
        players[playerAddress].fishCount[star] = newCount;
        emit FishCountUpdated(playerAddress, star, newCount);
    }

    function getCollectedGMC(
        address playerAddress
    ) external view returns (uint256) {
        require(registeredPlayers[playerAddress], "101");
        return players[playerAddress].collectedGMC;
    }

    function setCollectedGMC(
        address playerAddress,
        uint256 newAmount
    ) external onlyAdmin {
        require(registeredPlayers[playerAddress], "101");
        players[playerAddress].collectedGMC = newAmount;
        emit CollectedGMCUpdated(playerAddress, newAmount);
    }

    function getBaitCount(
        address playerAddress
    ) external view returns (uint256) {
        require(registeredPlayers[playerAddress], "101");
        return players[playerAddress].baitCount;
    }

    function setBaitCount(
        address playerAddress,
        uint256 newCount
    ) external onlyAdmin {
        require(registeredPlayers[playerAddress], "101");
        players[playerAddress].baitCount = newCount;
        emit BaitCountUpdated(playerAddress, newCount);
    }


    function claimGMC(address userAddress, uint256 count) external onlyAdmin {
        require(registeredPlayers[userAddress], "101");
        uint256 amount = players[userAddress].collectedGMC;  // 获取用户的collectedGMC
        require(amount >= count, "104");  // 确保有可领取的GMC
        gmcContract.mint(userAddress, count);  // 发送GMC到用户地址
        players[userAddress].collectedGMC = amount - count;  // 清空用户的collectedGMC
        emit ClaimGMC(userAddress, count);
    }

    function buyBaits(address userAddress, uint256 count) external onlyAdmin {
        require(registeredPlayers[userAddress], "101");
        uint256 totalPrice = count * baitPrice; // 计算总价格
        // 检查用户 GMC 余额
        require(gmcContract.balanceOf(userAddress) >= totalPrice, "103");
        // 扣除 GMC
        gmcContract.transfer(userAddress, address(this), totalPrice);
        // 增加用户的 baitCount
        players[userAddress].baitCount += count;
        emit BaitCountUpdated(userAddress, players[userAddress].baitCount);
    }


    function updateUserData(PlayerInfo[] memory playerInfo, address[] memory playerAddresses) external onlyAdmin {
        require(playerInfo.length == playerAddresses.length, "102");
        for (uint256 i = 0; i < playerInfo.length; i++) {
            require(registeredPlayers[playerAddresses[i]], "101");
            // 更新玩家信息
            players[playerAddresses[i]].fishingCount = playerInfo[i].fishingCount;
            players[playerAddresses[i]].experience = playerInfo[i].experience;
            players[playerAddresses[i]].level = playerInfo[i].level;
            players[playerAddresses[i]].unlockedFishingSpots = playerInfo[i].unlockedFishingSpots;
            players[playerAddresses[i]].currentFishingSpot = playerInfo[i].currentFishingSpot;
            players[playerAddresses[i]].fishPoolLevel = playerInfo[i].fishPoolLevel;
            players[playerAddresses[i]].interestRate = playerInfo[i].interestRate;
            players[playerAddresses[i]].collectedGMC = playerInfo[i].collectedGMC;
            players[playerAddresses[i]].baitCount = playerInfo[i].baitCount;
            players[playerAddresses[i]].fishCount = playerInfo[i].fishCount;
            players[playerAddresses[i]].currentFishermanNFT = playerInfo[i].currentFishermanNFT;
            players[playerAddresses[i]].currentRodNFT = playerInfo[i].currentRodNFT;
        }
        emit UserDataUpdate(playerInfo, playerAddresses);
    }

    function updateLimitAttribute(uint256 _levelUpLimit, uint256 _baitPurchaseLimit, uint256 _fishingCountLimit, uint256 _baitPrice)
    external onlyAdmin {
        levelUpLimit = _levelUpLimit;
        baitPurchaseLimit = _baitPurchaseLimit;
        fishingCountLimit = _fishingCountLimit;
        baitPrice = _baitPrice;
        emit LimitAttributeUpdate(levelUpLimit, baitPurchaseLimit, baitPrice);
    }

    function getPlayerInfo(address account) external view returns(PlayerInfo memory){
        return players[account];
    }


}
