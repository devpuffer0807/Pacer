// SPDX-License-Identifier: MIT
pragma solidity 0.8.4;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract DepoStaking is AccessControl {
    using SafeMath for uint256;

    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    // Staker contains info related to each staker.
    struct Staker {
        uint256 amount; // amount of tokens currently staked to the contract
        uint256 rewardDebt; // value needed for correct calculation staker's share
        uint256 distributed; // amount of distributed earned tokens
    }

    // ERC20 token staking to the contract.
    IERC20 public immutable _stakingToken;

    // ERC20 token earned by stakers as reward.
    IERC20 public immutable _rewardToken;

    // Common contract configuration variables.
    uint256 public immutable _rewardTotal;
    uint256 public immutable _startTime;
    uint256 public immutable _unlockTime;
    uint256 public immutable _endTime;
    uint256 public immutable _distributionTime;

    uint256 public _tokensPerStake;
    uint256 public _produced;

    uint256 public _staked;
    uint256 public _distributed;

    // Stakers info by token holders.
    mapping(address => Staker) public _stakers;

    constructor(
        address rewardToken,
        address stakingToken,
        uint256 rewardTotal,
        uint256 startTime
    ) {
        // Grant the contract deployer the default admin role: it will be able
        // to grant and revoke any roles
        _setupRole(DEFAULT_ADMIN_ROLE, msg.sender);
        _setupRole(ADMIN_ROLE, msg.sender);
        // Sets `DEFAULT_ADMIN_ROLE` as ``ADMIN_ROLE``'s admin role.
        _setRoleAdmin(ADMIN_ROLE, DEFAULT_ADMIN_ROLE);

        _rewardToken = IERC20(rewardToken);
        _stakingToken = IERC20(stakingToken);

        _rewardTotal = rewardTotal;
        _startTime = startTime;
        _unlockTime = startTime;
        _endTime = startTime + 60 days;
        _distributionTime = 60 days;
    }

    function initialize() public {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller is not an admin");

        // Transfer specified amount of reward tokens to the contract
        require(
            _rewardToken.transferFrom(msg.sender, address(this), _rewardTotal),
            "unable to transfer specified amount of reward tokens"
        );
    }

    function produced() public view returns (uint256) {
        if (block.timestamp < _startTime) {
            return 0;
        }
        if (block.timestamp >= _endTime) {
            return _rewardTotal;
        }
        return
            _rewardTotal.mul(block.timestamp - _startTime).div(
                _distributionTime
            );
    }

    function update() private {
        uint256 producedAtNow = produced();
        if (producedAtNow > _produced) {
            uint256 producedNew = producedAtNow.sub(_produced);
            _tokensPerStake = _tokensPerStake.add(
                producedNew.mul(1e18).div(_staked)
            );
            _produced = _produced.add(producedNew);
        }
    }

    function stake(uint256 amount) public {
        require(block.timestamp > _startTime, "staking time has not come yet");
        require(block.timestamp < _endTime, "staking time has expired");

        // Transfer specified amount of staking tokens to the contract
        require(
            _stakingToken.transferFrom(msg.sender, address(this), amount),
            "unable to transfer specified amount of staking tokens"
        );

        _staked = _staked.add(amount);

        Staker storage staker = _stakers[msg.sender];
        staker.amount = staker.amount.add(amount);
        staker.rewardDebt = staker.rewardDebt.add(
            amount.mul(_tokensPerStake).div(1e18)
        );

        update();
    }

    function unstake(uint256 amount) public {
        require(block.timestamp > _endTime, "unstaking is locked");

        Staker storage staker = _stakers[msg.sender];

        require(staker.amount > 0, "nothing to unstaking");

        staker.amount = staker.amount.sub(amount);

        _stakingToken.transfer(msg.sender, amount);
    }

    function calcReward(address _staker, uint256 _tps)
        private
        view
        returns (uint256 reward)
    {
        Staker storage staker = _stakers[_staker];

        if (staker.amount == 0) {
            return 0;
        }

        reward = staker.amount.mul(_tps).div(1e18).sub(staker.rewardDebt).sub(
            staker.distributed
        );

        return reward;
    }

    function claim() public {
        require(block.timestamp > _unlockTime, "claiming is locked");
        update();

        uint256 reward = calcReward(msg.sender, _tokensPerStake);
        require(reward > 0, "nothing to claim");

        Staker storage staker = _stakers[msg.sender];
        staker.distributed = staker.distributed.add(reward);

        _distributed = _distributed.add(reward);

        _rewardToken.transfer(msg.sender, reward);
    }

    function getClaim(address _staker) public view returns (uint256 reward) {
        uint256 _tps = _tokensPerStake;

        if (_staked == 0) {
            return 0;
        }

        uint256 producedAtNow = produced();
        if (producedAtNow > _produced) {
            uint256 producedNew = producedAtNow.sub(_produced);
            _tps = _tps.add(producedNew.mul(1e18).div(_staked));
        }

        reward = calcReward(_staker, _tps);

        return reward;
    }

    function claimAndUnstake() public {
        uint256 reward = getClaim(msg.sender);
        if (reward > 0) {
            claim();
        }
        Staker storage staker = _stakers[msg.sender];
        unstake(staker.amount);
    }

    function staked() public view returns (uint256) {
        return _staked;
    }

    function distributed() public view returns (uint256) {
        return _distributed;
    }
}
