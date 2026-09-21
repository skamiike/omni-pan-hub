// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OmniPanHub is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;
    uint256 private _jobIds;
    uint256 private _auctionIds;

    uint256 public platformFeePercentage = 5; // 5% fee for all transactions
    uint256 public creatorRoyaltyPercentage = 10; // 10% goes back to original creator on secondary sales

    // --- Commission (Primary Market) Structs ---
    struct Job {
        uint256 id;
        address client;
        address creator;
        uint256 price;
        string requirements;
        bool requiresApproval;
        bool isCompleted;
        bool isApproved;
        bool isCancelled;
    }

    mapping(uint256 => Job) public jobs;
    mapping(uint256 => address) public originalCreators; // Tracks original creator of an NFT for royalties

    // --- Marketplace (Secondary Market Fixed Price) Structs ---
    struct Listing {
        uint256 tokenId;
        address seller;
        uint256 price;
        bool isActive;
    }
    mapping(uint256 => Listing) public listings;

    // --- Auction Structs ---
    struct Auction {
        uint256 auctionId;
        uint256 tokenId;
        address seller;
        uint256 highestBid;
        address highestBidder;
        uint256 endTime;
        bool ended;
    }
    mapping(uint256 => Auction) public auctions;

    // --- Events ---
    event JobCreated(uint256 indexed jobId, address indexed client, address indexed creator, uint256 price, bool requiresApproval);
    event JobDelivered(uint256 indexed jobId, string tokenURI);
    event JobCompleted(uint256 indexed jobId, uint256 tokenId, string tokenURI);
    event ItemListed(uint256 indexed tokenId, address indexed seller, uint256 price);
    event ItemSold(uint256 indexed tokenId, address indexed buyer, address indexed seller, uint256 price);
    event AuctionStarted(uint256 indexed auctionId, uint256 indexed tokenId, address indexed seller, uint256 startingPrice, uint256 endTime);
    event BidPlaced(uint256 indexed auctionId, address indexed bidder, uint256 amount);
    event AuctionEnded(uint256 indexed auctionId, address indexed winner, uint256 amount);

    constructor() ERC721("OmniPanHub NFT", "OPH") Ownable(msg.sender) {}

    // ==========================================
    // 1. COMMISSION SYSTEM (Primary Market)
    // ==========================================
    
    function createJob(address _creator, string memory _requirements, bool _requiresApproval) external payable {
        require(msg.value > 0, "Price must be > 0");
        _jobIds++;
        jobs[_jobIds] = Job(_jobIds, msg.sender, _creator, msg.value, _requirements, _requiresApproval, false, false, false);
        emit JobCreated(_jobIds, msg.sender, _creator, msg.value, _requiresApproval);
    }

    function deliverJob(uint256 _jobId, string memory _tokenURI) external {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.creator, "Only creator");
        require(!job.isCompleted && !job.isCancelled, "Closed");
        if (!job.requiresApproval) {
            _finalizeJob(_jobId, _tokenURI);
        } else {
            emit JobDelivered(_jobId, _tokenURI);
        }
    }

    function approveJob(uint256 _jobId, string memory _tokenURI) external {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.client, "Only client");
        require(job.requiresApproval && !job.isCompleted && !job.isCancelled, "Invalid state");
        job.isApproved = true;
        _finalizeJob(_jobId, _tokenURI);
    }

    function _finalizeJob(uint256 _jobId, string memory _tokenURI) internal {
        Job storage job = jobs[_jobId];
        job.isCompleted = true;

        _tokenIds++;
        uint256 newItemId = _tokenIds;
        originalCreators[newItemId] = job.creator; // Record original creator for future royalties

        _mint(job.client, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        uint256 feeAmount = (job.price * platformFeePercentage) / 100;
        uint256 creatorAmount = job.price - feeAmount;

        payable(owner()).transfer(feeAmount);
        payable(job.creator).transfer(creatorAmount);

        emit JobCompleted(_jobId, newItemId, _tokenURI);
    }

    // ==========================================
    // 2. SECONDARY MARKETPLACE (Fixed Price)
    // ==========================================

    function listItem(uint256 _tokenId, uint256 _price) external {
        require(ownerOf(_tokenId) == msg.sender, "Not owner");
        require(_price > 0, "Price must be > 0");
        
        listings[_tokenId] = Listing(_tokenId, msg.sender, _price, true);
        emit ItemListed(_tokenId, msg.sender, _price);
    }

    function buyItem(uint256 _tokenId) external payable {
        Listing storage listing = listings[_tokenId];
        require(listing.isActive, "Not listed");
        require(msg.value == listing.price, "Incorrect price");

        listing.isActive = false;
        _handleSecondaryTransferAndFees(_tokenId, listing.seller, msg.sender, msg.value);
        emit ItemSold(_tokenId, msg.sender, listing.seller, msg.value);
    }

    // ==========================================
    // 3. AUCTION SYSTEM
    // ==========================================

    function startAuction(uint256 _tokenId, uint256 _startingPrice, uint256 _durationMinutes) external {
        require(ownerOf(_tokenId) == msg.sender, "Not owner");
        require(listings[_tokenId].isActive == false, "Item is listed for fixed price"); // Ensure not in marketplace
        
        _auctionIds++;
        uint256 newAuctionId = _auctionIds;
        
        auctions[newAuctionId] = Auction({
            auctionId: newAuctionId,
            tokenId: _tokenId,
            seller: msg.sender,
            highestBid: _startingPrice,
            highestBidder: address(0),
            endTime: block.timestamp + (_durationMinutes * 1 minutes),
            ended: false
        });

        emit AuctionStarted(newAuctionId, _tokenId, msg.sender, _startingPrice, auctions[newAuctionId].endTime);
    }

    function bid(uint256 _auctionId) external payable {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp < auction.endTime, "Auction ended");
        require(msg.value > auction.highestBid, "Bid too low");

        // Refund previous bidder if exists
        if (auction.highestBidder != address(0)) {
            payable(auction.highestBidder).transfer(auction.highestBid);
        }

        auction.highestBidder = msg.sender;
        auction.highestBid = msg.value;

        emit BidPlaced(_auctionId, msg.sender, msg.value);
    }

    function endAuction(uint256 _auctionId) external {
        Auction storage auction = auctions[_auctionId];
        require(block.timestamp >= auction.endTime, "Auction not yet ended");
        require(!auction.ended, "Already ended");

        auction.ended = true;

        if (auction.highestBidder != address(0)) {
            _handleSecondaryTransferAndFees(auction.tokenId, auction.seller, auction.highestBidder, auction.highestBid);
            emit AuctionEnded(_auctionId, auction.highestBidder, auction.highestBid);
        } else {
            // No bids
            emit AuctionEnded(_auctionId, address(0), 0);
        }
    }

    // ==========================================
    // SHARED UTILS (Royalties & Transfers)
    // ==========================================

    function _handleSecondaryTransferAndFees(uint256 _tokenId, address _seller, address _buyer, uint256 _price) internal {
        // 1. Calculate Fees
        uint256 platformFee = (_price * platformFeePercentage) / 100;
        uint256 royaltyFee = (_price * creatorRoyaltyPercentage) / 100;
        uint256 sellerAmount = _price - platformFee - royaltyFee;

        address originalCreator = originalCreators[_tokenId];

        // 2. Transfer NFT
        _transfer(_seller, _buyer, _tokenId);

        // 3. Distribute Funds
        payable(owner()).transfer(platformFee);
        if (originalCreator != address(0)) {
            payable(originalCreator).transfer(royaltyFee);
        } else {
            // If no original creator recorded, seller gets the royalty share
            sellerAmount += royaltyFee;
        }
        payable(_seller).transfer(sellerAmount);
    }
}
