// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

contract DecentralizedDeFiLendingPlatform is ReentrancyGuard {
    IERC20 public stablecoin; // Address of the stablecoin (e.g., USDT or DAI)
    
    struct Lender {
        uint depositAmount;
        uint interestRate; // Interest rate defined by lender in basis points (1% = 100 basis points)
        uint lastInterestWithdrawn;
        bool isAvailable;
    }

    struct Borrower {
        uint collateralAmount;
        uint loanAmount;
        uint interestRate; // Interest rate agreed between lender and borrower
        uint loanDueDate;
        address lender; // The address of the lender for this loan
        bool activeLoan;
    }

    mapping(address => Lender) public lenders;
    mapping(address => Borrower) public borrowers;

    // Events
    event LenderDeposited(address indexed lender, uint amount, uint interestRate);
    event LenderWithdrawn(address indexed lender, uint amount);
    event LoanRequested(address indexed borrower, uint collateralAmount, uint loanAmount, uint interestRate);
    event LoanRepaid(address indexed borrower, uint amount);
    event CollateralWithdrawn(address indexed borrower, uint amount);

    constructor(address _stablecoin) {
        stablecoin = IERC20(_stablecoin);
    }

    // Lender Functions
    function becomeLender(uint amount, uint interestRate) external nonReentrant {
        require(amount > 0, "Deposit amount must be greater than 0");
        require(interestRate > 0, "Interest rate must be positive");

        stablecoin.transferFrom(msg.sender, address(this), amount);
        lenders[msg.sender] = Lender({
            depositAmount: amount,
            interestRate: interestRate,
            lastInterestWithdrawn: block.timestamp,
            isAvailable: true
        });
        
        emit LenderDeposited(msg.sender, amount, interestRate);
    }

    function withdrawFunds(uint amount) external nonReentrant {
        Lender storage lender = lenders[msg.sender];
        require(lender.depositAmount >= amount, "Insufficient deposit amount");

        lender.depositAmount -= amount;
        if (lender.depositAmount == 0) {
            lender.isAvailable = false;
        }
        
        stablecoin.transfer(msg.sender, amount);
        emit LenderWithdrawn(msg.sender, amount);
    }

    // Borrower Functions
    function requestLoan(address lenderAddress, uint collateralAmount, uint loanAmount) external payable nonReentrant {
        Lender storage lender = lenders[lenderAddress];
        require(lender.isAvailable, "Lender not available");
        require(collateralAmount == msg.value, "Collateral must match the sent value");

        uint interestRate = lender.interestRate;
        borrowers[msg.sender] = Borrower({
            collateralAmount: collateralAmount,
            loanAmount: loanAmount,
            interestRate: interestRate,
            loanDueDate: block.timestamp + 30 days, // Custom loan duration can also be added
            lender: lenderAddress,
            activeLoan: true
        });

        lender.depositAmount -= loanAmount;
        stablecoin.transfer(msg.sender, loanAmount);

        emit LoanRequested(msg.sender, collateralAmount, loanAmount, interestRate);
    }

    function repayLoan() external nonReentrant {
        Borrower storage borrower = borrowers[msg.sender];
        require(borrower.activeLoan, "No active loan");
        uint interest = (borrower.loanAmount * borrower.interestRate) / 10000;
        uint totalRepayment = borrower.loanAmount + interest;

        stablecoin.transferFrom(msg.sender, address(this), totalRepayment);
        stablecoin.transfer(borrower.lender, totalRepayment);

        // Return collateral to the borrower
        uint collateralAmount = borrower.collateralAmount;
        borrower.activeLoan = false;
        payable(msg.sender).transfer(collateralAmount);

        emit LoanRepaid(msg.sender, totalRepayment);
    }

    // Interest Withdrawal by Lender
    function withdrawInterest() external nonReentrant {
        Lender storage lender = lenders[msg.sender];
        require(lender.depositAmount > 0, "No funds deposited");

        uint timeSinceLastWithdrawal = block.timestamp - lender.lastInterestWithdrawn;
        uint interest = (lender.depositAmount * lender.interestRate * timeSinceLastWithdrawal) / (365 days * 10000);

        lender.lastInterestWithdrawn = block.timestamp;
        stablecoin.transfer(msg.sender, interest);
    }

    // Utility Functions
    function getLoanDetails(address borrower) external view returns (uint, uint, uint, address, bool) {
        Borrower storage b = borrowers[borrower];
        return (b.collateralAmount, b.loanAmount, b.interestRate, b.lender, b.activeLoan);
    }

    function getLenderDetails(address lender) external view returns (uint, uint, bool) {
        Lender storage l = lenders[lender];
        return (l.depositAmount, l.interestRate, l.isAvailable);
    }
}
