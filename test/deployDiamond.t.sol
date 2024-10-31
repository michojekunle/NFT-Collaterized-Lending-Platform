// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import {NFTCollateralFacet} from "../contracts/facets/NFTCollateralFacet.sol";
import {LoanFacet} from "../contracts/facets/LoanFacet.sol";
import {FundManagementFacet} from "../contracts/facets/FundManagementFacet.sol";
import "../contracts/Diamond.sol";

import "./helpers/DiamondUtils.sol";

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    NFTCollateralFacet nftCltF;
    LoanFacet loanF;
    FundManagementFacet fundMgmtF;

    // setup tests
    function setUp() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        nftCltF = new NFTCollateralFacet();
        loanF = new LoanFacet(address(nftCltF));
        fundMgmtF = new FundManagementFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](5);

        cut[0] = (
            FacetCut({
                facetAddress: address(dLoupe),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("DiamondLoupeFacet")
            })
        );

        cut[1] = (
            FacetCut({
                facetAddress: address(ownerF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("OwnershipFacet")
            })
        );

        cut[2] = (
            FacetCut({
                facetAddress: address(nftCltF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("NFTCollateralFacet")
            })
        );

        cut[3] = (
            FacetCut({
                facetAddress: address(loanF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("LoanFacet")
            })
        );

        cut[4] = (
            FacetCut({
                facetAddress: address(fundMgmtF),
                action: FacetCutAction.Add,
                functionSelectors: generateSelectors("FundManagementFacet")
            })
        );

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    // tests for nft collateral and loan management features
    function test_NFT_Collateral() public {}

    function test_Loan_Management() public {}

    // Test the deposit functionality in FundManagementFacet
    function testDepositFunds() public {
        uint256 depositAmount = 2 ether;

        // Deposit into the diamond
        (bool success, ) = address(diamond).call{value: depositAmount}(
            abi.encodeWithSignature("deposit()")
        );
        require(success, "Deposit failed");

        // Check if the funds are recorded correctly
        uint256 availableFunds = FundManagementFacet(address(diamond))
            .getAvailableFunds();
        assertEq(
            availableFunds,
            depositAmount,
            "Available funds after deposit are incorrect"
        );
    }

    // Test the withdraw functionality in FundManagementFacet
    function testWithdrawFunds() public {
        uint256 depositAmount = 2 ether;
        uint256 withdrawAmount = 1 ether;

        // First deposit
        (bool successDeposit, ) = address(diamond).call{value: depositAmount}(
            abi.encodeWithSignature("deposit()")
        );
        require(successDeposit, "Initial deposit failed");

        // Withdraw from the diamond
        FundManagementFacet(address(diamond)).withdraw(withdrawAmount);

        // Verify remaining balance
        uint256 availableFunds = FundManagementFacet(address(diamond))
            .getAvailableFunds();
        assertEq(
            availableFunds,
            depositAmount - withdrawAmount,
            "Available funds after withdrawal are incorrect"
        );

        // Verify contract balance in Diamond
        uint256 contractBalance = address(diamond).balance;
        assertEq(
            contractBalance,
            depositAmount - withdrawAmount,
            "Diamond balance after withdrawal is incorrect"
        );
    }

    // Test insufficient withdrawal protection in FundManagementFacet
    function testWithdrawMoreThanAvailable() public {
        uint256 depositAmount = 1 ether;
        uint256 overdrawAmount = 2 ether;

        // Deposit into the diamond
        (bool successDeposit, ) = address(diamond).call{value: depositAmount}(
            abi.encodeWithSignature("deposit()")
        );
        require(successDeposit, "Deposit failed");

        // Attempt to withdraw more than available
        vm.expectRevert("Insufficient funds"); 
        FundManagementFacet(address(diamond)).withdraw(overdrawAmount);
    }

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}

    receive() external payable {}
}
