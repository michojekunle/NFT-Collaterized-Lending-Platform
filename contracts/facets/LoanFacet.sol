// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./NFTCollateralFacet.sol";
import "../libraries/LibDiamond.sol";

contract LoanFacet {
    constructor(address _nftCollateralFacetAddress) {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.nftCollateralFacetAddress = _nftCollateralFacetAddress;
    }

    // Create a loan with fixed interest rate
    function createLoan(uint256 _amount) external {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Collateral storage collateral = ds.collaterals[msg.sender];

        require(collateral.isCollateralized, "No collateral deposited");
        require(!ds.loans[msg.sender].isActive, "Existing loan active");

        uint256 interestRate = LibDiamond.interestRate();
        uint256 interestAmount = (_amount * interestRate) / 100;

        ds.loans[msg.sender] = LibDiamond.Loan({
            amount: _amount + interestAmount,
            dueDate: block.timestamp + LibDiamond.loanDuration,
            isActive: true
        });

        collateral.loanAmount = _amount;
        payable(msg.sender).transfer(_amount);

        emit LibDiamond.LoanCreated(msg.sender, _amount, interestRate);
    }

    // Repay the loan
    function repayLoan() external payable {
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        LibDiamond.Loan storage loan = ds.loans[msg.sender];
        require(loan.isActive, "No active loan");

        require(msg.value >= loan.amount, "Insufficient amount to repay loan");

        loan.isActive = false;
        emit LibDiamond.LoanRepaid(msg.sender, msg.value);

        NFTCollateralFacet(ds.nftCollateralFacetAddress).releaseNFT(msg.sender);
    }

    // Liquidate the loan if past due date
    function liquidateLoan(address _user) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        LibDiamond.Loan storage loan = ds.loans[_user];
        require(loan.isActive, "No active loan");
        require(block.timestamp > loan.dueDate, "Loan not overdue");

        loan.isActive = false;
        NFTCollateralFacet(ds.nftCollateralFacetAddress).seizeNFT(_user);

        emit LibDiamond.LoanLiquidated(_user);
    }

    function updateNftCollateralFacetAddress(
        address _nftCollateralFacetAddress
    ) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.nftCollateralFacetAddress = _nftCollateralFacetAddress;

        emit LibDiamond.NftCollateralFacetAddressUpdated(
            _nftCollateralFacetAddress
        );
    }
}
