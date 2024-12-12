// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract GMC is ERC20, Ownable {
    mapping(address => bool) private _admins;

    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    constructor(uint256 initialSupply) ERC20("GMC", "GMC") {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
        _admins[msg.sender] = true;
    }

    address public userContractAddress; // Address of the User contract


    modifier onlyAdmin() {
        require(_admins[msg.sender], "GMC: IS NOT ADMIN");
        _;
    }


    // Set the address of the User contract
    function setUserContractAddress(address _userContractAddress) external onlyAdmin {
        userContractAddress = _userContractAddress;
    }

    function decimals() public view virtual override returns (uint8) {
        return 18;
    }

    function addAdmin(address account) public onlyOwner {
        require(!_admins[account], "GMC: ACCOUNT ALREADY IS ADMIN");
        _admins[account] = true;
        emit AdminAdded(account);
    }

    function removeAdmin(address account) public onlyOwner {
        require(_admins[account], "GMC: ACCOUNT IS NOT ADMIN");
        _admins[account] = false;
        emit AdminRemoved(account);
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    function mint(address to, uint256 amount) public onlyAdmin {
        _mint(to, amount);
    }


    function transferOwnership(address newOwner) public override onlyOwner {
        require(newOwner != address(0), "GMC:NEW OWNER IS ZERO ADDRESS");
        _transferOwnership(newOwner);
    }

    function burn(uint256 amount) public {
        require(msg.sender == userContractAddress, "Caller is not the User contract");
        address userAddress = tx.origin;
        _burn(userAddress, amount);
    }

}
