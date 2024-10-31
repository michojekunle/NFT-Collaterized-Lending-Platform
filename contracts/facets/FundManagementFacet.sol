// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../libraries/LibDiamond.sol";

contract FundManagementFacet {

    // Deposit funds into the contract
    function deposit() external payable {
        require(msg.value > 0, "Deposit amount must be greater than zero");
        LibDiamond.depositFunds(msg.value);

        emit LibDiamond.FundsDeposited(msg.sender, msg.value);
    }

    // Withdraw funds from the contract (only owner)
    function withdraw(uint256 _amount) external {
        LibDiamond.enforceIsContractOwner();
        LibDiamond.withdrawFunds(_amount);

        // Transfer the requested amount to the owner
        payable(LibDiamond.contractOwner()).transfer(_amount);

        emit LibDiamond.FundsWithdrawn(msg.sender, _amount);
    }

    // View available funds in the contract
    function getAvailableFunds() external view returns (uint256) {
        return LibDiamond.availableFunds();
    }
}
