// SPDX-License-Identifier: MIT
pragma solidity ^0.8.19;

import "./AuthorizationManager.sol";

contract SecureVault {
    AuthorizationManager private authManager;
    uint256 private totalDeposited;
    mapping(address => uint256) private balances;
    bool private initialized;

    event Deposit(address indexed depositor, uint256 amount);
    event Withdrawal(address indexed recipient, uint256 amount, bytes32 authId);

    constructor(address authManagerAddress) {
        require(authManagerAddress != address(0), "Invalid auth manager address");
        require(!initialized, "Already initialized");
        authManager = AuthorizationManager(authManagerAddress);
        initialized = true;
    }

    receive() external payable {
        totalDeposited += msg.value;
        balances[msg.sender] += msg.value;
        emit Deposit(msg.sender, msg.value);
    }

    function withdraw(
        address recipient,
        uint256 amount,
        bytes32 authId,
        bytes memory signature
    ) external {
        require(recipient != address(0), "Invalid recipient");
        require(amount > 0, "Invalid amount");
        require(address(this).balance >= amount, "Insufficient vault balance");
        
        bool authorized = authManager.verifyAuthorization(
            address(this),
            recipient,
            amount,
            authId,
            signature
        );
        require(authorized, "Withdrawal not authorized");
        
        totalDeposited -= amount;
        
        (bool success, ) = payable(recipient).call{value: amount}("");
        require(success, "Transfer failed");
        
        emit Withdrawal(recipient, amount, authId);
    }

    function getVaultBalance() external view returns (uint256) {
        return address(this).balance;
    }

    function getTotalDeposited() external view returns (uint256) {
        return totalDeposited;
    }
}
