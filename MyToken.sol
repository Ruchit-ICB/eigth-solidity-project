// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

// ✅ Importing from jsDelivr CDN (works reliably in Remix)
import "https://cdn.jsdelivr.net/npm/@openzeppelin/contracts@4.9.3/token/ERC721/IERC721.sol";
import "https://cdn.jsdelivr.net/npm/@openzeppelin/contracts@4.9.3/security/ReentrancyGuard.sol";

contract NFTMarketplace is ReentrancyGuard {
    uint public listingCounter;

    struct Listing {
        uint id;
        address seller;
        address nftAddress;
        uint tokenId;
        uint price;
        bool isSold;
    }

    mapping(uint => Listing) public listings;

    event NFTListed(uint id, address seller, address nftAddress, uint tokenId, uint price);
    event NFTPurchased(uint id, address buyer);

    // 🟩 List an NFT for sale
    function listNFT(address nftAddress, uint tokenId, uint price) external {
        require(price > 0, "Price must be greater than 0");

        IERC721 nft = IERC721(nftAddress);
        require(nft.ownerOf(tokenId) == msg.sender, "You do not own this NFT");
        require(nft.getApproved(tokenId) == address(this), "Marketplace not approved");

        listingCounter++;
        listings[listingCounter] = Listing({
            id: listingCounter,
            seller: msg.sender,
            nftAddress: nftAddress,
            tokenId: tokenId,
            price: price,
            isSold: false
        });

        emit NFTListed(listingCounter, msg.sender, nftAddress, tokenId, price);
    }

    // 🟨 Buy a listed NFT
    function buyNFT(uint listingId) external payable nonReentrant {
        Listing storage item = listings[listingId];
        require(!item.isSold, "Item already sold");
        require(msg.value == item.price, "Incorrect ETH amount");

        item.isSold = true;

        payable(item.seller).transfer(msg.value);
        IERC721(item.nftAddress).safeTransferFrom(item.seller, msg.sender, item.tokenId);

        emit NFTPurchased(listingId, msg.sender);
    }

    // 🟦 View listing details
    function getListing(uint listingId) external view returns (
        address seller,
        address nftAddress,
        uint tokenId,
        uint price,
        bool isSold
    ) {
        Listing storage item = listings[listingId];
        return (
            item.seller,
            item.nftAddress,
            item.tokenId,
            item.price,
            item.isSold
        );
    }
}
