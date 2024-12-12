// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OOC is ERC20, Ownable {
    // 事件
    event Mint(address indexed to, uint256 amount);
    event Burn(address indexed from, uint256 amount);
    event AdminAdded(address indexed account);
    event AdminRemoved(address indexed account);

    // Admin role management
    mapping(address => bool) private _admins;

    constructor(uint256 initialSupply) ERC20("OOC", "OOC") {
        _mint(msg.sender, initialSupply * (10 ** decimals()));
    }

    // Modifiers
    modifier onlyAdmin() {
        require(_admins[msg.sender] || owner() == msg.sender, "Not an admin or owner");
        _;
    }

    // Admin management functions
    function addAdmin(address account) external onlyOwner {
        require(!_admins[account], "Account is already an admin");
        _admins[account] = true;
        emit AdminAdded(account);
    }

    function removeAdmin(address account) external onlyOwner {
        require(_admins[account], "Account is not an admin");
        _admins[account] = false;
        emit AdminRemoved(account);
    }

    function isAdmin(address account) public view returns (bool) {
        return _admins[account];
    }

    // 铸造代币
    function mint(address to, uint256 amount) external onlyAdmin {
        _mint(to, amount);
        emit Mint(to, amount);
    }

    // 销毁代币
    function burn(uint256 amount) external {
        _burn(msg.sender, amount);
        emit Burn(msg.sender, amount);
    }

    // 允许合约拥有者设置新的合约拥有者
    function transferOwnership(address newOwner) public override onlyOwner {
        super.transferOwnership(newOwner);
    }
}
