// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract User is Ownable {
    struct PlayerInfo {
        uint256 fishingCount;
        uint256 experience;
        uint256 level;
        uint256 currentFishermanNFT;
        uint256 currentRodNFT;
        bool[150] unlockedFishingSpots;
        uint256 currentFishingSpot;
        uint256 fishPoolLevel;
        uint256[10] fishCount;
        uint256 interestRate;
        uint256 collectedGMC;
        uint256 baitCount;
    }

    address private _pendingOwner;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");
    uint256 public levelUpLimit;
    uint256[] public experienceConfig;
    uint256 public baitPurchaseLimit;
    uint256 public fishingCountLimit;
    uint256 public baitPrice;

    mapping(address => PlayerInfo) private players;
    mapping(address => bool) private registeredPlayers;

    event PlayerAdded(address indexed playerAddress);
    event FishingCountDecreased(address indexed playerAddress, uint256 count);
    event FishingCountRecovered(address indexed playerAddress, uint256 count);
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
    event FishingSpotSwitched(address indexed playerAddress, uint256 newSpotId);
    event FishingSpotUnlocked(address indexed playerAddress, uint256 spotId);

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

    constructor() {
        levelUpLimit = 100; // 设置默认等级上限
        baitPurchaseLimit = 99; // 设置默认鱼饵购买上限
        fishingCountLimit = 10; // 设置默认钓鱼次数上限
        baitPrice = 0.0001 ether;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyRegisteredPlayer() {
        require(registeredPlayers[msg.sender], "Player not registered");
        _;
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
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
        require(newOwner != address(0), "New owner is the zero address");
        _pendingOwner = newOwner;
        emit OwnershipTransferStarted(owner(), newOwner);
    }

    function acceptOwnership() public virtual {
        require(msg.sender == _pendingOwner, "Caller is not the pending owner");
        _transferOwnership(_pendingOwner);
        _pendingOwner = address(0);
    }

    function addUser(address userAddress) external onlyAdmin {
        require(!registeredPlayers[userAddress], "Player already registered");

        players[userAddress] = PlayerInfo({
            fishingCount: 0,
            experience: 0,
            level: 1,
            currentFishermanNFT: 0,
            currentRodNFT: 0,
            currentFishingSpot: 0,
            fishPoolLevel: 1,
            fishCount: [-1, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            interestRate: 0,
            collectedGMC: 0,
            baitCount: 0
        });

        players[userAddress][0] = true; // 设置第一个为true
        for (uint i = 1; i < unlockedFishingSpots.length; i++) {
            players[userAddress][i] = false; // 其余设置为false
        }

        registeredPlayers[userAddress] = true;
        emit PlayerAdded(userAddress);
    }

    function getUser(
        address userAddress
    ) external view onlyAdmin returns (PlayerInfo memory) {
        require(registeredPlayers[userAddress], "Player not registered");
        return players[userAddress];
    }

    function decreaseFishingCount(
        address userAddress,
        uint256 count
    ) external onlyAdmin {
        require(registeredPlayers[userAddress], "Player not registered");
        require(
            players[userAddress].fishingCount >= count,
            "Insufficient fishing count"
        );

        players[userAddress].fishingCount -= count;
        emit FishingCountDecreased(userAddress, count);
    }

    function recoverFishingCount(
        address userAddress,
        uint256 count
    ) external onlyAdmin {
        require(registeredPlayers[userAddress], "Player not registered");

        players[userAddress].fishingCount += count;
        if (players[userAddress].fishingCount > fishingCountLimit) {
            players[userAddress].fishingCount = fishingCountLimit;
        }
        emit FishingCountRecovered(userAddress, count);
    }

    function addExperience(
        address userAddress,
        uint256 exp
    ) external onlyAdmin {
        require(registeredPlayers[userAddress], "Player not registered");
        require(experienceConfig.length > 0, "Experience config not set");

        PlayerInfo storage player = players[userAddress];
        player.experience += exp;

        while (
            player.level < levelUpLimit &&
            player.experience >= experienceConfig[player.level - 1]
        ) {
            player.experience -= experienceConfig[player.level - 1];
            player.level++;
            emit PlayerLeveledUp(userAddress, player.level);
        }

        emit ExperienceAdded(userAddress, exp, player.experience);
    }

    function changeFisherman(
        address userAddress,
        uint256 fishermanId
    ) external onlyAdmin {
        require(registeredPlayers[userAddress], "Player not registered");
        players[msg.userAddress].currentFishermanNFT = fishermanId;
        emit FishermanChanged(userAddress, fishermanId);
    }

    function changeRod(uint256 rodId, address userAddress) external onlyAdmin {
        require(registeredPlayers[userAddress], "Player not registered");
        players[msg.userAddress].currentRodNFT = rodId;
        emit RodChanged(userAddress, rodId);
    }

    function switchFishingSpot(
        uint256 spotId,
        address userAddress
    ) external onlyAdmin {
        require(registeredPlayers[userAddress], "Player not registered");
        require(
            players[userAddress].unlockedFishingSpots[spotId],
            "Fishing spot not unlocked"
        );

        players[userAddress].currentFishingSpot = spotId;
        emit FishingSpotSwitched(userAddress, spotId);
    }

    function getUnlockedFishingSpots(
        address userAddress
    ) external view returns (bool[3] memory) {
        require(registeredPlayers[userAddress], "Player not registered");
        return players[userAddress].unlockedFishingSpots;
    }

    function unlockFishingSpot(
        address userAddress,
        uint256 spotId
    ) external onlyAdmin {
        require(registeredPlayers[userAddress], "Player not registered");
        require(
            !players[userAddress].unlockedFishingSpots[spotId],
            "Fishing spot already unlocked"
        );

        players[userAddress].unlockedFishingSpots[spotId] = true;
        emit FishingSpotUnlocked(userAddress, spotId);
    }

    function getLevelUpLimit() external view returns (uint256) {
        return levelUpLimit;
    }

    function setLevelUpLimit(uint256 _levelUpLimit) external onlyAdmin {
        levelUpLimit = _levelUpLimit;
    }

    function setExperienceConfig(
        uint256[] calldata _experienceConfig
    ) external onlyAdmin {
        experienceConfig = _experienceConfig;
    }

    function getExperienceConfig() external view returns (uint256[] memory) {
        return experienceConfig;
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
        require(registeredPlayers[playerAddress], "Player not registered");
        return players[playerAddress].level;
    }

    function setPlayerLevel(
        address playerAddress,
        uint256 newLevel
    ) external onlyAdmin {
        require(registeredPlayers[playerAddress], "Player not registered");
        require(newLevel <= levelUpLimit, "Level exceeds limit");
        players[playerAddress].level = newLevel;
        emit PlayerLevelUpdated(playerAddress, newLevel);
    }

    function getFishPoolLevel(
        address playerAddress
    ) external view returns (uint256) {
        require(registeredPlayers[playerAddress], "Player not registered");
        return players[playerAddress].fishPoolLevel;
    }

    function setFishPoolLevel(
        address playerAddress,
        uint256 newLevel
    ) external onlyAdmin {
        require(registeredPlayers[playerAddress], "Player not registered");
        players[playerAddress].fishPoolLevel = newLevel;
        emit FishPoolLevelUpdated(playerAddress, newLevel);
    }

    function getFishCount(
        address playerAddress
    ) external view returns (uint256[]) {
        require(registeredPlayers[playerAddress], "Player not registered");
        return players[playerAddress].fishCount;
    }

    function setFishCount(
        address playerAddress,
        uint256 star,
        uint256 newCount
    ) external onlyAdmin {
        require(registeredPlayers[playerAddress], "Player not registered");
        players[playerAddress].fishCount[star] = newCount;
        emit FishCountUpdated(playerAddress, newCount);
    }

    function getCollectedGMC(
        address playerAddress
    ) external view returns (uint256) {
        require(registeredPlayers[playerAddress], "Player not registered");
        return players[playerAddress].collectedGMC;
    }

    function setCollectedGMC(
        address playerAddress,
        uint256 newAmount
    ) external onlyAdmin {
        require(registeredPlayers[playerAddress], "Player not registered");
        players[playerAddress].collectedGMC = newAmount;
        emit CollectedGMCUpdated(playerAddress, newAmount);
    }

    function getBaitCount(
        address playerAddress
    ) external view returns (uint256) {
        require(registeredPlayers[playerAddress], "Player not registered");
        return players[playerAddress].baitCount;
    }

    function setBaitCount(
        address playerAddress,
        uint256 newCount
    ) external onlyAdmin {
        require(registeredPlayers[playerAddress], "Player not registered");
        players[playerAddress].baitCount = newCount;
        emit BaitCountUpdated(playerAddress, newCount);
    }
}
