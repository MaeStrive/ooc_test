// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FishingSpot is Ownable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // 鱼的结构
    struct Fish {
        uint256 id;
        string fishName;
        string res;
        uint256 rarityID;
        uint256 rarityNum;
        uint256 fishFarm;
        string fishFramName;
        uint256 price;
        uint256 output;
        string rarity;
    }

    struct SpotConfig {
        string fishFramName;
        Fish[] fishList;
        uint8 entryLevel;
    }

    mapping(uint256 => SpotConfig) private spotConfigs;
    uint256[] private spotIds;

    event FishingSpotAdded(
        uint256 indexed spotId,
        string fishFramName,
        uint8 entryLevel
    );
    event FishingSpotUpdated(
        uint256 indexed spotId,
        string fishFramName,
        uint8 entryLevel
    );

    constructor() {
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }

    modifier onlyAdmin() {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");
        _;
    }

    function addFishingSpot(
        uint256 spotId,
        string memory fishFramName,
        Fish[] memory fishList,
        uint8 entryLevel
    ) external onlyAdmin returns (bool) {
        SpotConfig storage spotConfig = spotConfigs[spotId];
        spotConfig.entryLevel = entryLevel;

        // 清空之前的鱼列表
        delete spotConfig.fishList;

        // 将 memory 数组逐个复制到 storage 中
        for (uint256 i = 0; i < fishList.length; i++) {
            spotConfig.fishList.push(fishList[i]);
        }

        spotIds.push(spotId);

        emit FishingSpotAdded(spotId, fishFramName, entryLevel);
        return true;
    }



    function updateFishingSpot(
        uint256 spotId,
        string memory fishFramName,
        Fish[] memory fishList,
        uint8 entryLevel
    ) external onlyAdmin returns (bool) {

        SpotConfig storage spotConfig = spotConfigs[spotId];
        // 清空之前的鱼列表
        delete spotConfig.fishList;
        spotConfig.entryLevel = entryLevel;

        // 将 memory 数组逐个复制到 storage 中
        for (uint256 i = 0; i < fishList.length; i++) {
            spotConfig.fishList.push(fishList[i]);
        }

        emit FishingSpotUpdated(spotId, fishFramName, entryLevel);
        return true;
    }

    function getFishingSpotConfig(
        uint256 spotId
    ) external view returns (SpotConfig memory) {
        return spotConfigs[spotId];
    }

    function getAllFishingSpotIds() external view returns (uint256[] memory) {
        return spotIds;
    }

    function addAdmin(address newAdmin) external onlyOwner {
        grantRole(ADMIN_ROLE, newAdmin);
    }

    function removeAdmin(address admin) external onlyOwner {
        revokeRole(ADMIN_ROLE, admin);
    }

    function renounceAdmin() external {
        renounceRole(ADMIN_ROLE, msg.sender);
    }
}
