// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/**
 * @title SecureFundManagement
 * @dev A secure fund management smart contract that allows an owner to deposit and withdraw funds
 * with proper access control and error handling
 */
contract SecureFundManagement {
    // State variables
    address public owner;
    uint256 public balance;
    
    // Custom error enumeration
    enum Error {
        None,
        InsufficientBalance,
        NotAuthorized
    }
    
    // Events for logging
    event Deposit(address indexed depositor, uint256 amount, uint256 newBalance);
    event Withdrawal(address indexed recipient, uint256 amount, uint256 newBalance);
    event OwnershipTransferred(address indexed previousOwner, address indexed newOwner);
    
    // Custom errors for gas efficiency (Solidity 0.8.4+)
    error Unauthorized(address caller);
    error InsufficientFunds(uint256 requested, uint256 available);
    error ZeroAmount();
    error ZeroAddress();
    
    // Modifiers
    modifier onlyOwner() {
        if (msg.sender != owner) {
            revert Unauthorized(msg.sender);
        }
        _;
    }
    
    modifier validAmount(uint256 amount) {
        if (amount == 0) {
            revert ZeroAmount();
        }
        _;
    }
    
    /**
     * @dev Constructor sets the contract deployer as the owner
     */
    constructor() {
        owner = msg.sender;
        balance = 0;
    }
    
    /**
     * @dev Allows anyone to deposit funds into the contract
     * @return success Boolean indicating successful deposit
     */
    function deposit() public payable validAmount(msg.value) returns (bool success) {
        balance += msg.value;
        emit Deposit(msg.sender, msg.value, balance);
        return true;
    }
    
    /**
     * @dev Allows the owner to withdraw funds from the contract
     * @param amount The amount to withdraw in wei
     * @return error Error enum indicating the result of the withdrawal
     */
    function withdraw(uint256 amount) public onlyOwner validAmount(amount) returns (Error error) {
        // Check for sufficient balance
        if (amount > balance) {
            revert InsufficientFunds(amount, balance);
        }
        
        // Update balance before transfer (Checks-Effects-Interactions pattern)
        balance -= amount;
        
        // Transfer funds to owner
        (bool sent, ) = payable(owner).call{value: amount}("");
        require(sent, "Failed to send Ether");
        
        emit Withdrawal(owner, amount, balance);
        return Error.None;
    }
    
    /**
     * @dev Returns the contract balance
     * @return The current balance in wei
     */
    function getBalance() public view returns (uint256) {
        return balance;
    }
    
    /**
     * @dev Returns the actual contract balance (including any direct transfers)
     * @return The actual contract balance in wei
     */
    function getContractBalance() public view returns (uint256) {
        return address(this).balance;
    }
    
    /**
     * @dev Transfers ownership of the contract to a new owner
     * @param newOwner The address of the new owner
     */
    function transferOwnership(address newOwner) public onlyOwner {
        if (newOwner == address(0)) {
            revert ZeroAddress();
        }
        address previousOwner = owner;
        owner = newOwner;
        emit OwnershipTransferred(previousOwner, newOwner);
    }
    
    /**
     * @dev Allows the contract to receive Ether directly
     */
    receive() external payable {
        balance += msg.value;
        emit Deposit(msg.sender, msg.value, balance);
    }
    
    /**
     * @dev Fallback function
     */
    fallback() external payable {
        balance += msg.value;
        emit Deposit(msg.sender, msg.value, balance);
    }
}
