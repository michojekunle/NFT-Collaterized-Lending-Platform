// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;

import "../contracts/interfaces/IDiamondCut.sol";
import "../contracts/facets/DiamondCutFacet.sol";
import "../contracts/facets/DiamondLoupeFacet.sol";
import "../contracts/facets/OwnershipFacet.sol";
import "../contracts/facets/NFTCollateralFacet.sol";
import "../contracts/facets/LoanFacet.sol";
import "../contracts/Diamond.sol";

import "./helpers/DiamondUtils.sol";

contract TestNft is ERC721 {
    
}

contract DiamondDeployer is DiamondUtils, IDiamondCut {
    //contract types of facets to be deployed
    Diamond diamond;
    DiamondCutFacet dCutFacet;
    DiamondLoupeFacet dLoupe;
    OwnershipFacet ownerF;
    NFTCollateralFacet nftCltF;
    LoanFacet loanF;

    function testDeployDiamond() public {
        //deploy facets
        dCutFacet = new DiamondCutFacet();
        diamond = new Diamond(address(this), address(dCutFacet));
        dLoupe = new DiamondLoupeFacet();
        ownerF = new OwnershipFacet();
        nftCltF = new NFTCollateralFacet();
        loanF = new LoanFacet();

        //upgrade diamond with facets

        //build cut struct
        FacetCut[] memory cut = new FacetCut[](4);

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

        //upgrade diamond
        IDiamondCut(address(diamond)).diamondCut(cut, address(0x0), "");

        //call a function
        DiamondLoupeFacet(address(diamond)).facetAddresses();
    }

    // tests for nft collateral and loan management features
    function test_NFT_Collateral() public {}
    
    function test_Loan_Management() public {}

    function diamondCut(
        FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external override {}
}
