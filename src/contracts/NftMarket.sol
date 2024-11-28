// SPDX-License-Identifier: SEE LICENSE IN LICENSE
pragma solidity ^0.8.28;

import {ERC721} from "openzeppelin-contracts/contracts/token/ERC721/ERC721.sol";
import {ERC721URIStorage} from "openzeppelin-contracts/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import {Ownable} from "openzeppelin-contracts/contracts/access/Ownable.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract NFTMarket is ERC721, ERC721URIStorage, Ownable, ReentrancyGuard {
    uint256 private _tokenIdCounter;
    uint256 private _totalSupply;

    struct Sale {
        uint256 price;
        address seller;
    }

    struct Auction {
        address seller;
        uint256 startingPrice;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool active;
    }

    mapping(uint256 => Auction) private _auctions;

    mapping(uint256 => Sale) private _sales;
    mapping(uint256 => uint256) private _royalties;
    mapping(uint256 => address) private _creators;

    event AuctionStarted(uint256 tokenId, uint256 startingPrice, uint256 endTime);
    event NewBid(uint256 tokenId, address bidder, uint256 amount);
    event AuctionEnded(uint256 tokenId, address winner, uint256 amount);
    event AuctionCanceled(uint256 tokenId);
    event NFTListed(uint256 tokenId, uint256 price, address seller);
    event NFTSold(uint256 tokenId, uint256 price, address buyer);

    constructor() ERC721("Mklee", "MKL") Ownable(msg.sender) {
        _tokenIdCounter = 1; // Initialize tokenId counter
    }

    function safeMint(address _to, string memory uri) public {
        uint256 tokenId = _incrementTokenId();
        _creators[tokenId] = msg.sender;
        _safeMint(_to, tokenId);
        _setTokenURI(tokenId, uri);
        _totalSupply++;
    }

    // Function to increment and return the current token ID
    function _incrementTokenId() internal returns (uint256) {
        return _tokenIdCounter++;
    }

    function totalSupply() public view returns (uint256) {
        return _totalSupply;
    }

    function getAuction(uint256 _tokenId) public view returns (Auction memory) {
        return _auctions[_tokenId];
    }

    function setRoyalty(uint256 _tokenId, uint256 _percentage) public {
        require(ownerOf(_tokenId) == msg.sender, "Only the owner can set royalties.");
        require(_percentage <= 10, "Royalty cannot exceed 10%.");
        _royalties[_tokenId] = _percentage;
    }

    function getRoyalty(uint256 _tokenId) public view returns (uint256) {
        return _royalties[_tokenId];
    }

    function _exists(uint256 _tokenId) internal view returns (bool) {
        Sale memory sale = _sales[_tokenId];
        return sale.price > 0;
    }

    // Overriding supportsInterface to handle both ERC721 and ERC721URIStorage
    function supportsInterface(bytes4 interfaceId) public view override(ERC721, ERC721URIStorage) returns (bool) {
        return super.supportsInterface(interfaceId);
    }

    // Overriding tokenURI function to handle both ERC721 and ERC721URIStorage
    function tokenURI(uint256 tokenId) public view override(ERC721, ERC721URIStorage) returns (string memory) {
        return super.tokenURI(tokenId);
    }

    //Function to list NFT for sale
    function listForSale(uint256 _tokenId, uint256 _price) public {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(_sales[_tokenId].price == 0, "NFT is already listed for sale.");
        require(_price > 0, "Price must be greater than zero.");
        _sales[_tokenId] = Sale(_price, msg.sender);

        emit NFTListed(_tokenId, _price, msg.sender);
    }

    //Function to buy NFT
    function buy(uint256 _tokenId) public payable nonReentrant {
        Sale memory sale = _sales[_tokenId];
        require(_exists(_tokenId), "Token ID does not exist.");
        require(sale.price > 0, "This NFT is not for sale");
        require(msg.value == sale.price, "Incorrect amount sent");
        uint256 royalty = (sale.price * _royalties[_tokenId]) / 100;
        uint256 sellerAmount = sale.price - royalty;

        (bool royaltySent,) = _creators[_tokenId].call{value: royalty}("");
        require(royaltySent, "Royalty transfer failed");

        (bool sellerSent,) = sale.seller.call{value: sellerAmount}("");
        require(sellerSent, "Seller payment transfer failed");

        //Transfer the NFT to the buyer
        _transfer(sale.seller, msg.sender, _tokenId);

        //Remove the sale listing
        delete _sales[_tokenId];
        emit NFTSold(_tokenId, sale.price, msg.sender);
    }

    //Function remove nft from market place
    function cancelSale(uint256 _tokenId) public {
        Sale memory sale = _sales[_tokenId];
        require(sale.seller == msg.sender, "You are not the seller.");
        delete _sales[_tokenId];
    }

    //function to auction NFT
    function auctionNFT(uint256 _tokenId, uint256 _startingPrice, uint256 _duration) public {
        require(ownerOf(_tokenId) == msg.sender, "You are not the owner of this NFT.");
        require(!_auctions[_tokenId].active, "Auction already active for this NFT.");
        require(_startingPrice > 0, "Starting price must be greater than zero.");

        //Transfer NFT to contract for escrow during auction
        _transfer(msg.sender, address(this), _tokenId);

        //Initialize auction
        _auctions[_tokenId] = Auction({
            seller: msg.sender,
            startingPrice: _startingPrice,
            highestBid: 0,
            highestBidder: address(0),
            endTime: block.timestamp + _duration,
            active: true
        });

        emit AuctionStarted(_tokenId, _startingPrice, block.timestamp + _duration);
    }

    //Function to bid NFT
    function placeBid(uint256 _tokenId) public payable nonReentrant {
        Auction storage auction = _auctions[_tokenId];
        require(auction.active, "No active auction for this NFT.");
        require(block.timestamp < auction.endTime, "Auction has ended.");
        require(msg.value > auction.startingPrice, "Bid must be higher than starting price");
        require(msg.value > auction.highestBid, "Bid must be higher than the current highest bid.");

        //Refund the previous highest bidder
        if (auction.highestBid > 0) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        //Update auction with new highest bid
        auction.highestBid = msg.value;
        auction.highestBidder = msg.sender;

        emit NewBid(_tokenId, msg.sender, msg.value);
    }

    //Function to End Auction
    function endAuction(uint256 _tokenId) public {
        Auction storage auction = _auctions[_tokenId];
        require(auction.active, "No active auction for this NFT.");
        require(block.timestamp >= auction.endTime, "Auction has not ended yet.");

        //Transfer NFT to the highest bidder or back to the seller if no bids
        if (auction.highestBidder != address(0)) {
            _transfer(address(this), auction.highestBidder, _tokenId);
            payable(auction.highestBidder).transfer(auction.highestBid);
        } else {
            //Return NFT to the seller if no bids
            _transfer(address(this), auction.seller, _tokenId);
        }

        //Mark auction as inactive
        auction.active = false;

        emit AuctionEnded(_tokenId, auction.highestBidder, auction.highestBid);
    }

    //Function to Cancel Auction
    function cancelAuction(uint256 _tokenId) public {
        Auction storage auction = _auctions[_tokenId];
        require(auction.active, "No active auction for this NFT.");
        require(msg.sender == auction.seller, "Only the seller can cancel the auction.");
        require(block.timestamp < auction.endTime, "Auction already ended.");

        //Return NFT to the Seller
        _transfer(address(this), auction.seller, _tokenId);

        //Mark auction as inactive
        auction.active = false;
        emit AuctionCanceled(_tokenId);
    }

    function getListedNFTs() public view returns (uint256[] memory) {
        uint256 totalTokens = totalSupply();
        uint256 listedCount = 0;

        // Count the listed tokens
        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_sales[i].price > 0) {
                listedCount++;
            }
        }

        // Create an array with the exact size
        uint256[] memory tokensForSale = new uint256[](listedCount);
        uint256 counter = 0;

        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_sales[i].price > 0) {
                tokensForSale[counter] = i;
                counter++;
            }
        }

        return tokensForSale;
    }

    function getAuctions() public view returns (uint256[] memory) {
        uint256 totalTokens = totalSupply();
        uint256 auctionCount = 0;

        // Count the active auctions
        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_auctions[i].active) {
                auctionCount++;
            }
        }

        // Create an array with the exact size
        uint256[] memory activeAuctions = new uint256[](auctionCount);
        uint256 counter = 0;

        for (uint256 i = 1; i <= totalTokens; i++) {
            if (_auctions[i].active) {
                activeAuctions[counter] = i;
                counter++;
            }
        }

        return activeAuctions;
    }

    receive() external payable {}
    fallback() external payable {}
}
