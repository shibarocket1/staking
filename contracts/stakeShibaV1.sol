// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts-upgradeable/token/ERC20/utils/SafeERC20Upgradeable.sol";
import "@openzeppelin/contracts-upgradeable/proxy/utils/Initializable.sol";

/**
 * @dev A token holder contract that will allow a beneficiary to extract the
 * tokens after a given release time.
 *
 * Useful for simple vesting schedules like "advisors get all of their tokens
 * after 1 year".
 */
library SafeMath {
    function add(uint256 a, uint256 b) internal pure returns (uint256) {
        uint256 c = a + b;
        require(c >= a, "SafeMath: addition overflow");

        return c;
    }

    function sub(uint256 a, uint256 b) internal pure returns (uint256) {
        return sub(a, b, "SafeMath: subtraction overflow");
    }

    function sub(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b <= a, errorMessage);
        uint256 c = a - b;

        return c;
    }

    function mul(uint256 a, uint256 b) internal pure returns (uint256) {
        // Gas optimization: this is cheaper than requiring 'a' not being zero, but the
        // benefit is lost if 'b' is also tested.
        // See: https://github.com/OpenZeppelin/openzeppelin-contracts/pull/522
        if (a == 0) {
            return 0;
        }

        uint256 c = a * b;
        require(c / a == b, "SafeMath: multiplication overflow");

        return c;
    }

    function div(uint256 a, uint256 b) internal pure returns (uint256) {
        return div(a, b, "SafeMath: division by zero");
    }

    function div(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b > 0, errorMessage);
        uint256 c = a / b;
        // assert(a == b * c + a % b); // There is no case in which this doesn't hold

        return c;
    }

    function mod(uint256 a, uint256 b) internal pure returns (uint256) {
        return mod(a, b, "SafeMath: modulo by zero");
    }

    function mod(uint256 a, uint256 b, string memory errorMessage) internal pure returns (uint256) {
        require(b != 0, errorMessage);
        return a % b;
    }
}

library Staker{
    struct data{
        uint256 stakedAmount;
        uint256 package;
        uint256 lastRewardTime;
        uint256 claimed;
        bool status;
    }
 }

contract stakeShibaV1 is Initializable {
    using SafeERC20Upgradeable for IERC20Upgradeable;
    using Staker for Staker.data;
    using SafeMath for uint256;

    // ERC20 basic token contract being held
    IERC20Upgradeable private  _token;
    
    uint private activeStakers;
    address private owner;
    mapping(address => Staker.data) public stakers;
    mapping(uint256 => uint256) private stakingAPYs;
    mapping(uint256 => uint256) packages;
    mapping(uint256 => uint256) updatedTime;
    uint256 public totalStaked;
    uint256 public totalClaimed;
    uint256 public stakersLimit;
    
    event NewStake(uint256 amount, address staker, uint256 package);

    function initialize(IERC20Upgradeable token_, uint256 apy0, uint256 apy1, uint256 apy2) public initializer  {
        _token = token_;
        owner = msg.sender;
        updatedTime[0] = block.timestamp;
        updatedTime[1] = block.timestamp;
        updatedTime[2] = block.timestamp;
        stakingAPYs[0] = apy0; // 100 = 1% or 10 = 0.1% or 1 = 0.01%
        stakingAPYs[1] = apy1;
        stakingAPYs[2] = apy2;
        stakersLimit = 1000;
        packages[0] = 100000 ether;
        packages[1] = 250000 ether;
        packages[2] = 500000 ether;
    }
    
    modifier onlyOwner() {
        require(owner == msg.sender, "Ownable: caller is not the owner");
        _;
    }

    /**
     * @return the token being held.
     */
    function token() public view virtual returns (IERC20Upgradeable) {
        return _token;
    }
    
    /**
     * Stake Amount in the contract.
     */
    function StakeAmount(uint _package) public{
        require(_package <= 2, 'Invalid Staking Package');
        require(stakersLimit > activeStakers,"Staking Limit Exceeded");
        require(!stakers[msg.sender].status,"Already staked with this account");
        
        // Stake Brownce
        if(_package == 0){
            _stakeBrownce();
        }
        // Stake Silver
        else if(_package == 1){
            _stakeSilver();
        }
        // Stake Gold
        else if(_package == 2){
            _stakeGold();
        }
    }
    
    function _stakeBrownce() internal{
        stakers[msg.sender].stakedAmount = packages[0];
        stakers[msg.sender].package = 1;
        stakers[msg.sender].lastRewardTime = block.timestamp;
        stakers[msg.sender].status = true;
        
        totalStaked += packages[0];
        token().safeTransferFrom(msg.sender, address(this), packages[0]);
        
        activeStakers++;
        emit NewStake(packages[0],msg.sender,1);
    }
    
    function _stakeSilver() internal{
        stakers[msg.sender].stakedAmount = packages[1];
        stakers[msg.sender].package = 2;
        stakers[msg.sender].lastRewardTime = block.timestamp;
        stakers[msg.sender].status = true;
        
        totalStaked += packages[1];
        token().safeTransferFrom(msg.sender, address(this), packages[1]);
        
        activeStakers++;
        emit NewStake(packages[1],msg.sender,2);
    }
    
    function _stakeGold() internal{
        stakers[msg.sender].stakedAmount = packages[2];
        stakers[msg.sender].package = 3;
        stakers[msg.sender].lastRewardTime = block.timestamp;
        stakers[msg.sender].status = true;
        
        totalStaked += packages[2];
        token().safeTransferFrom(msg.sender, address(this), packages[2]);
        
        activeStakers++;
        emit NewStake(packages[2],msg.sender,3);
    }
    
    function checkRewards() public view returns(uint256, uint256){
        require(stakers[msg.sender].status,'You are not a staker');
        Staker.data memory stakee = stakers[msg.sender];
        uint256 perDayReward = stakee.stakedAmount.mul(stakingAPYs[stakee.package]).div(10000).div(365);
        uint256 claimableDays;
        if(stakee.lastRewardTime > updatedTime[stakee.package - 1]){
            claimableDays = block.timestamp.sub(stakee.lastRewardTime).div(1 days);
        }else{
            claimableDays = block.timestamp.sub(updatedTime[stakee.package - 1]).div(1 days);
        }
        uint256 claimableReward = perDayReward.mul(claimableDays);
        return (claimableDays,claimableReward);
    }
    
    /**
        * ClaimRewards:
        * Calculate and transfer rewards to staker, calculate reward from last reward time or update time 
        * if staking apy event occurs between staking period
     **/
    function claimRewards() public{
        require(stakers[msg.sender].status, 'You are not a staker');
        require(block.timestamp.sub(stakers[msg.sender].lastRewardTime).div(1 days) > 0,'Already Claimed Today');
        uint256 perDayReward = stakers[msg.sender].stakedAmount.mul(stakingAPYs[stakers[msg.sender].package]).div(10000).div(365);
        uint256 claimableDays;
        
        if(stakers[msg.sender].lastRewardTime > updatedTime[stakers[msg.sender].package - 1]){
            claimableDays = block.timestamp.sub(stakers[msg.sender].lastRewardTime).div(1 days);
        }else{
            claimableDays = block.timestamp.sub(updatedTime[stakers[msg.sender].package - 1]).div(1 days);
        }
        
        uint256 claimableReward = perDayReward.mul(claimableDays);
        require(claimableReward < RemainingRewardsPot(), 'Reward Pot is empty');
        
        _token.safeTransfer(msg.sender,claimableReward);
        
        stakers[msg.sender].lastRewardTime += (claimableDays) * 1 days;
        stakers[msg.sender].claimed += claimableReward;
        
    }
    
    function endStake() public{
        require(stakers[msg.sender].status, 'You are not a staker');
        require(block.timestamp.sub(stakers[msg.sender].lastRewardTime).div(1 days) == 0,'Please claim all rewards before ending the staking');
        _token.safeTransfer(msg.sender, stakers[msg.sender].stakedAmount);
        stakers[msg.sender].status = false;
        stakers[msg.sender].stakedAmount = 0;
        stakers[msg.sender].package = 0;
        activeStakers--;
    }
    
    function calculatePerDayRewards(uint256 amount, uint256 stakePlan) public view returns(uint256){
        uint256 perDayReward = amount.mul(stakingAPYs[stakePlan]).div(10000).div(365);
        return (perDayReward);
    }
    
    function RemainingRewardsPot() public view virtual returns (uint256) {
        return token().balanceOf(address(this)) - totalStaked;
    }
    
    function withdrawRewardsPot(uint256 amount) public onlyOwner {
        require(amount < RemainingRewardsPot(), 'Insufficient funds in RewardPot');
        _token.safeTransfer(msg.sender, amount);
    }
    
    //For Testing Purpose
    // function changeLastRewardTime(uint256 _lastrewardTime) public onlyOwner{
    //     stakers[msg.sender].lastRewardTime = _lastrewardTime;
    // }

    function changeStakersLimit(uint256 _limit) public onlyOwner{
        require(_limit > 0,"Stakers Limit Must Be greater than 0");
        stakersLimit = _limit;
    }    

    function currentTimestamp() public view returns(uint256){
        return block.timestamp;
    }
    
    /**
     * Change APY Functions:
     * Change APY with update time , so every staker should need to claim their rewards,
     * before any change apy event occurs
    **/
    function changeBrownceAPY(uint256 newAPY, uint256 _updatedTime) public onlyOwner{
        require(newAPY < 100000, 'APY cannot exceet 1000%');
        stakingAPYs[0] = newAPY;
        updatedTime[0] = _updatedTime;
    }
    
    function changeSilverAPY(uint256 newAPY, uint256 _updatedTime) public onlyOwner{
        require(newAPY < 100000, 'APY cannot exceet 1000%');
        stakingAPYs[1] = newAPY;
        updatedTime[1] = _updatedTime;
    }
    
    function changeGoldAPY(uint256 newAPY, uint256 _updatedTime) public onlyOwner{
        require(newAPY < 100000, 'APY cannot exceet 1000%');
        stakingAPYs[2] = newAPY;
        updatedTime[2] = _updatedTime;
    }
}