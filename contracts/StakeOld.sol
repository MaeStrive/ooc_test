// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/access/Ownable.sol";


interface IGMC {
    function mint(address to, uint256 amount) external;

    function balanceOf(address account) external view returns (uint256);

    function transfer(address sender, address recipient, uint256 amount) external;

}

interface IOOC {
    function transferFrom(address from, address to, uint256 amount) external returns (bool);

    function balanceOf(address account) external view returns (uint256);

}

contract StakeOld is ReentrancyGuard, AccessControl, Ownable {
    using SafeMath for uint256;

    // 质押的GMC代币
    IGMC public stakingToken;
    // 奖励的OOC代币
    IOOC public rewardToken;


    address private _pendingOwner;

    // 质押奖励的发放速率
    uint256 public rewardRate = 0;
    uint256 public rewardsDuration = 7 days;

    // 每次有用户操作时，更新为当前时间
    uint256 public lastUpdateTime;
    // 奖励累加值
    uint256 public rewardPerTokenStored;

    // 用户的奖励累加值
    mapping(address => uint256) public userRewardPerTokenPaid;
    // 用户可领取的奖励数量
    mapping(address => uint256) public rewards;
    // 池子中质押总量
    uint256 private _totalSupply;
    // 用户的余额
    mapping(address => uint256) private _balances;

    // 活动结束时间
    uint256 public periodFinish;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");


    event Staked(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event RewardPaid(address indexed user, uint256 reward);
    event OwnershipTransferStarted(
        address indexed previousOwner,
        address indexed newOwner
    );
    event RewardAdded(uint256 reward);
    event RewardsDurationUpdated(uint256 newDuration);


    constructor(IGMC _stakingToken, IOOC _rewardToken) {
        stakingToken = _stakingToken;
        rewardToken = _rewardToken;
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
    }


    function balanceOf(address account) external view returns (uint256) {
        return _balances[account];
    }

    function totalSupply() external view returns (uint256) {
        return _totalSupply;
    }

    // 计算当前时刻的累加值
    function rewardPerToken() public view returns (uint256) {
        if (_totalSupply == 0) {
            return rewardPerTokenStored;
        }
        return rewardPerTokenStored.add(
            lastTimeRewardApplicable().sub(lastUpdateTime).mul(rewardRate).mul(1e18).div(_totalSupply)
        );
    }

    // 获取当前有效时间
    function lastTimeRewardApplicable() public view returns (uint256) {
        return block.timestamp < periodFinish ? block.timestamp : periodFinish;
    }

    function getRewardForDuration() external view returns (uint256) {
        return rewardRate.mul(rewardsDuration);
    }

    // 计算用户可以领取的奖励数量
    function earned(address account) public view returns (uint256) {
        return _balances[account]
        .mul(rewardPerToken().sub(userRewardPerTokenPaid[account]))
        .div(1e18)
        .add(rewards[account]);
    }

    modifier updateReward(address account) {
        rewardPerTokenStored = rewardPerToken();
        lastUpdateTime = lastTimeRewardApplicable();
        if (account != address(0)) {
            rewards[account] = earned(account);
            userRewardPerTokenPaid[account] = rewardPerTokenStored;
        }
        _;
    }

    function stake(uint256 amount) external nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot stake 0");
        _totalSupply = _totalSupply.add(amount);
        _balances[msg.sender] = _balances[msg.sender].add(amount);
        stakingToken.transfer(msg.sender, address(this), amount);
        emit Staked(msg.sender, amount);
    }

    function withdraw(uint256 amount) public nonReentrant updateReward(msg.sender) {
        require(amount > 0, "Cannot withdraw 0");
        _totalSupply = _totalSupply.sub(amount);
        _balances[msg.sender] = _balances[msg.sender].sub(amount);
        stakingToken.transfer(address(this), msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function getReward() public nonReentrant updateReward(msg.sender) {
        uint256 reward = rewards[msg.sender];
        if (reward > 0) {
            rewards[msg.sender] = 0;
            rewardToken.transferFrom(address(this), msg.sender, reward);
            emit RewardPaid(msg.sender, reward);
        }
    }

    function exit() external {
        withdraw(_balances[msg.sender]);
        getReward();
    }

    // 设置奖励的发放速率和结束时间
    function notifyRewardAmount(uint256 reward) external onlyAdmin updateReward(address(0)) {
        if (block.timestamp >= periodFinish) {
            rewardRate = reward.div(rewardsDuration);
        } else {
            uint256 remaining = periodFinish.sub(block.timestamp);
            uint256 leftover = remaining.mul(rewardRate);
            rewardRate = reward.add(leftover).div(rewardsDuration);
        }

        // Ensure the provided reward amount is not more than the balance in the contract.
        // This keeps the reward rate in the right range, preventing overflows due to
        // very high values of rewardRate in the earned and rewardsPerToken functions;
        // Reward + leftover must be less than 2^256 / 10^18 to avoid overflow.
        uint balance = rewardToken.balanceOf(address(this));
        require(rewardRate <= balance.div(rewardsDuration), "Provided reward too high");

        lastUpdateTime = block.timestamp;
        periodFinish = block.timestamp.add(rewardsDuration);
        emit RewardAdded(reward);
    }

    function setRewardsDuration(uint256 _rewardsDuration) external onlyAdmin {
        require(
            block.timestamp > periodFinish,
            "Previous rewards period must be complete before changing the duration for the new period"
        );
        rewardsDuration = _rewardsDuration;
        emit RewardsDurationUpdated(rewardsDuration);
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
}
