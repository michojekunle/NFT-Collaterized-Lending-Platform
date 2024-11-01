// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {LibDiamond} from "../libraries/LibDiamond.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721.sol";
import "openzeppelin-contracts/contracts/token/ERC721/IERC721Receiver.sol";

contract NFTCollateralFacet is IERC721Receiver {
    // Deposit NFT as collateral
    function depositNFT(address _nftContract, uint256 _nftId) external {
        IERC721 nft = IERC721(_nftContract);
        require(nft.ownerOf(_nftId) == msg.sender, "You must own the NFT");

        nft.transferFrom(msg.sender, address(this), _nftId);

        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        ds.collaterals[msg.sender] = LibDiamond.Collateral({
            nftAddress: _nftContract,
            tokenId: _nftId,
            loanAmount: 0,
            isCollateralized: true
        });

        emit LibDiamond.NFTDeposited(msg.sender, _nftContract, _nftId);
    }

    // Release NFT back to the user after repayment
    function releaseNFT(address _user) external {
        LibDiamond.enforceIsContractAuthorized(); // Ensure only diamond owner or authorized contract can release NFT
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();

        LibDiamond.Collateral storage collateral = ds.collaterals[_user];
        require(collateral.isCollateralized, "No collateral to release");

        IERC721(collateral.nftAddress).transferFrom(
            address(this),
            _user,
            collateral.tokenId
        );

        collateral.isCollateralized = false;
        emit LibDiamond.NFTReleased(
            _user,
            collateral.nftAddress,
            collateral.tokenId
        );
    }

    // Seize NFT in case of default
    function seizeNFT(address _user) external {
        LibDiamond.enforceIsContractAuthorized(); // Ensure only diamond owner or authorized contract can seize NFT
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        LibDiamond.Collateral memory collateral = ds.collaterals[_user];
        require(collateral.isCollateralized, "No collateral to seize");

        IERC721(collateral.nftAddress).transferFrom(
            address(this),
            LibDiamond.contractOwner(),
            collateral.tokenId
        );

        collateral.isCollateralized = false;
        emit LibDiamond.NFTSeized(
            _user,
            collateral.nftAddress,
            collateral.tokenId
        );
    }

    function onERC721Received(
        address operator,
        address from,
        uint256 tokenId,
        bytes calldata data
    ) external pure override returns (bytes4) {
        // This function simply returns a specific selector to indicate the contract can receive NFTs
        return IERC721Receiver.onERC721Received.selector;
    }
}
