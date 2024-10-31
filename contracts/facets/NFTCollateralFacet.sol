// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "../libraries/LibDiamond.sol";

contract NFTCollateralFacet {
    // Deposit NFT as collateral
    function depositNFT(address _nftContract, uint256 _nftId) external {
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_nftId) == msg.sender, "You must own the NFT");

        nft.transferFrom(msg.sender, address(this), _nftId);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        ds.collaterals[msg.sender] = LibDiamond.Collateral({
            nftContract: _nftContract,
            nftId: _nftId,
            isCollateralized: true
        });

        emit LibDiamond.NFTDeposited(msg.sender, _nftContract, _nftId);
    }

    // Release NFT back to the user after repayment
    function releaseNFT(address _user) external {
        LibDiamond.enforceIsContractOwner(); // Ensure only diamond owner can release NFT
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        
        LibDiamond.Collateral storage collateral = ds.collaterals[_user];
        require(collateral.isCollateralized, "No collateral to release");

        IERC721(collateral.nftContract).transferFrom(address(this), _user, collateral.nftId);

        collateral.isCollateralized = false;
        emit LibDiamond.NFTReleased(_user, collateral.nftContract, collateral.nftId);
    }

    // Seize NFT in case of default
    function seizeNFT(address _user) external {
        LibDiamond.enforceIsContractOwner(); // Only diamond owner can seize NFT
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Collateral memory collateral = ds.collaterals[_user];
        require(collateral.isCollateralized, "No collateral to seize");

        IERC721(collateral.nftContract).transferFrom(address(this), LibDiamond.contractOwner(), collateral.nftId);

        collateral.isCollateralized = false;
        emit LibDiamond.NFTSeized(_user, collateral.nftContract, collateral.nftId);
    }
}
