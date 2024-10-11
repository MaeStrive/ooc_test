// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";

contract FishingSpot is Ownable, AccessControl {
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    struct SpotConfig {
        uint8 starLevel;
        uint256[] fishList;
        uint8 entryLevel;
    }

    mapping(uint256 => SpotConfig) private spotConfigs;
    uint256[] private spotIds;

    event FishingSpotAdded(
        uint256 indexed spotId,
        uint8 starLevel,
        uint8 entryLevel
    );
    event FishingSpotUpdated(
        uint256 indexed spotId,
        uint8 starLevel,
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
        uint8 starLevel,
        uint256[] memory fishList,
        uint8 entryLevel
    ) external onlyAdmin returns (bool) {
        require(
            spotConfigs[spotId].starLevel == 0,
            "Fishing spot already exists"
        );

        spotConfigs[spotId] = SpotConfig({
            starLevel: starLevel,
            fishList: fishList,
            entryLevel: entryLevel
        });

        spotIds.push(spotId);

        emit FishingSpotAdded(spotId, starLevel, entryLevel);
        return true;
    }

    function updateFishingSpot(
        uint256 spotId,
        uint8 starLevel,
        uint256[] memory fishList,
        uint8 entryLevel
    ) external onlyAdmin returns (bool) {
        require(
            spotConfigs[spotId].starLevel != 0,
            "Fishing spot does not exist"
        );

        spotConfigs[spotId] = SpotConfig({
            starLevel: starLevel,
            fishList: fishList,
            entryLevel: entryLevel
        });

        emit FishingSpotUpdated(spotId, starLevel, entryLevel);
        return true;
    }

    function getFishingSpotConfig(
        uint256 spotId
    ) external view returns (SpotConfig memory) {
        require(
            spotConfigs[spotId].starLevel != 0,
            "Fishing spot does not exist"
        );
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
