// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

interface IGMC {

    function balanceOf(address account) external view returns (uint256);
    function safeTransferFrom(address from,address to,uint256 value) external view returns (uint256);
    function safeTransfer(address to,uint256 value) external view returns (uint256);

}

interface IOOC {
    function balanceOf(address account) external view returns (uint256);
    function safeTransferFrom(address from,address to,uint256 value) external view returns (uint256);
    function safeTransfer(address to,uint256 value) external view returns (uint256);

}

contract Stake is Ownable {
    using SafeERC20 for IERC20;

    IOOC public rewardToken;
    IGMC public lpToken;

    uint256 public rewardRate; // Reward tokens per block
    uint256 public lastUpdateBlock;
    uint256 public rewardPerTokenStored;

    mapping(address => uint256) public userRewardPerTokenPaid;
    mapping(address => uint256) public rewards;

    uint256 private _totalSupply;
    mapping(address => uint256) private _balances;

    event RewardAdded(uint256 reward);
    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);

    constructor(address _rewardToken, address _lpToken, uint256 _rewardRate) {
        rewardToken = IOOC(_rewardToken);
        lpToken = IGMC(_lpToken);
        rewardRate = _rewardRate;
        lastUpdateBlock = block.number;
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateBlock = block.number;
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return
            rewardPerTokenStored +
            ((block.number - lastUpdateBlock) * rewardRate * 1e18) /
            _totalSupply;
    }

    function earned(address account) public view returns (uint256) {
        return
            (_balances[account] *
                (rewardPerToken() - userRewardPerTokenPaid[account])) /
            1e18 +
            rewards[account];
    }

    function stake(uint256 amount) external updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply += amount;
        _balances[msg.sender] += amount;
        lpToken.safeTransferFrom(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply -= amount;
        _balances[msg.sender] -= amount;
        lpToken.safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.safeTransfer(msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    function addReward(uint256 reward) external onlyOwner updateReward(address(0)) {
        rewardToken.safeTransferFrom(msg.sender, address(this), reward);
        emit RewardAdded(reward);
    }
}
