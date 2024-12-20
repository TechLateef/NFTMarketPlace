// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity 0.8.28;

import {Test, console} from "forge-std/Test.sol";
import "../src/contracts/NftMarket.sol";

contract NFTMarketTest is Test {
    NFTMarket public nftMarket;
    address public mk = address(0x1);
    address public bob = address(0x2);

    function setUp() public {
        //Deploy NFTMarket contract
        nftMarket = new NFTMarket();
        //Mint an NFT for mk
        vm.prank(mk);
        nftMarket.safeMint(mk, "ipfs://metadata1");
    }

    function testMint() public {
        //verify totatl supply increases after minting
        uint256 totalSupplyBefore = nftMarket.totalSupply();
        vm.prank(mk);
        nftMarket.safeMint(mk, "ipfs://metadata2");

        vm.prank(mk);
        nftMarket.setRoyalty(1, 5);

        uint256 totalSupplyAfter = nftMarket.totalSupply();

        assertEq(totalSupplyAfter, totalSupplyBefore + 1, "Total supply did not increase");
    }

    function testBuy() public {
        //Mk lists his NFT for sale
        vm.prank(mk);
        nftMarket.listForSale(1, 1 ether);

        //Bob buys the Nft
        vm.prank(bob);
        vm.deal(bob, 3 ether);
        nftMarket.buy{value: 1 ether}(1);
        assertEq(nftMarket.ownerOf(1), bob, "Owner should be Bob after purchase");
    }

    function testAuction() public {
        //mk start an auction for his NFT
        vm.prank(mk);
        nftMarket.auctionNFT(1, 1 ether, 1 days);

        //check auction state
        NFTMarket.Auction memory auction = nftMarket.getAuction(1);

        assertEq(auction.seller, mk, "Auction seller should be Alice");
        assertEq(auction.startingPrice, 1 ether, "Starting price should be 1 ether");
        assertEq(auction.highestBid, 0, "Highest bid should be 0 initially");
        assertTrue(auction.active, "Auction should be active");
    }

    function testBid() public {
        // Start auction
        vm.prank(mk);
        nftMarket.auctionNFT(1, 1 ether, 1 days);

        vm.prank(bob);
        vm.deal(bob, 3 ether);
        nftMarket.placeBid{value: 1.5 ether}(1);

        NFTMarket.Auction memory auction = nftMarket.getAuction(1);

        assertEq(auction.highestBidder, bob, "Starting price should be 1 ether");
        assertEq(auction.highestBid, 1.5 ether, "Highest bid should be 0 initially");
        assertTrue(auction.active, "Auction should be active");
    }

    function testEndAuction() public {
        // Start auction
        vm.prank(mk);
        nftMarket.auctionNFT(1, 1 ether, 1 days);

        vm.prank(bob);
        vm.deal(bob, 3 ether);
        nftMarket.placeBid{value: 1.5 ether}(1);

        // Fast-forward time to end the auction
        vm.warp(block.timestamp + 2 days);

        vm.prank(mk);
        nftMarket.endAuction(1);

        assertEq(nftMarket.ownerOf(1), bob, "Owner should be Bob after auction ends");
    }

    function testCancelAuction() public {
        // Start auction
        vm.prank(mk);
        nftMarket.auctionNFT(1, 1 ether, 1 days);

        vm.prank(mk);
        nftMarket.cancelAuction(1);

        assertEq(nftMarket.ownerOf(1), mk, "Owner should be seller");
    }

    function testNonSellerCannotEndAuction() public {
        // Setup: Seller (mk) auctions an NFT
        vm.prank(mk);
        nftMarket.auctionNFT(1, 100 ether, 1 days); // Seller mk starts an auction

        // Perform: Non-seller (bob) tries to cancel the auction
        vm.prank(bob); // Simulate calling the function from bob's address
        vm.expectRevert("Only the seller can cancel the auction."); // Expect revert message
        nftMarket.cancelAuction(1); // Non-seller should not be able to cancel the auction
    }
}
