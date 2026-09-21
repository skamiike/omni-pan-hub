// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract OmniPanHub is ERC721URIStorage, Ownable {
    uint256 private _tokenIds;
    uint256 private _jobIds;

    uint256 public platformFeePercentage = 5; // 5% fee

    struct Job {
        uint256 id;
        address client;
        address creator;
        uint256 price;
        string requirements;
        bool isCompleted;
        bool isCancelled;
    }

    mapping(uint256 => Job) public jobs;

    event JobCreated(uint256 indexed jobId, address indexed client, address indexed creator, uint256 price);
    event JobCompleted(uint256 indexed jobId, uint256 tokenId, string tokenURI);
    event JobCancelled(uint256 indexed jobId);

    constructor() ERC721("OmniPanHub NFT", "OPH") Ownable(msg.sender) {}

    // Client creates a job and deposits funds
    function createJob(address _creator, string memory _requirements) external payable {
        require(msg.value > 0, "Price must be greater than 0");
        require(_creator != address(0) && _creator != msg.sender, "Invalid creator");

        _jobIds++;
        uint256 newJobId = _jobIds;

        jobs[newJobId] = Job({
            id: newJobId,
            client: msg.sender,
            creator: _creator,
            price: msg.value,
            requirements: _requirements,
            isCompleted: false,
            isCancelled: false
        });

        emit JobCreated(newJobId, msg.sender, _creator, msg.value);
    }

    // Creator completes the job, mints the NFT to the client, and funds are split
    function completeJob(uint256 _jobId, string memory _tokenURI) external {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.creator, "Only creator can complete");
        require(!job.isCompleted && !job.isCancelled, "Job already closed");

        job.isCompleted = true;

        // Mint NFT to the client
        _tokenIds++;
        uint256 newItemId = _tokenIds;
        _mint(job.client, newItemId);
        _setTokenURI(newItemId, _tokenURI);

        // Split payments
        uint256 feeAmount = (job.price * platformFeePercentage) / 100;
        uint256 creatorAmount = job.price - feeAmount;

        // Send platform fee to owner
        (bool feeSuccess, ) = owner().call{value: feeAmount}("");
        require(feeSuccess, "Fee transfer failed");

        // Send payment to creator
        (bool creatorSuccess, ) = job.creator.call{value: creatorAmount}("");
        require(creatorSuccess, "Creator transfer failed");

        emit JobCompleted(_jobId, newItemId, _tokenURI);
    }

    // Client or Creator can cancel if mutually agreed or timeout (simplified for now to just owner/client)
    function cancelJob(uint256 _jobId) external {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.client || msg.sender == owner(), "Not authorized");
        require(!job.isCompleted && !job.isCancelled, "Job already closed");

        job.isCancelled = true;

        // Refund client
        (bool refundSuccess, ) = job.client.call{value: job.price}("");
        require(refundSuccess, "Refund failed");

        emit JobCancelled(_jobId);
    }

    // Allows owner to update fee
    function setPlatformFee(uint256 _newFee) external onlyOwner {
        require(_newFee <= 20, "Fee too high");
        platformFeePercentage = _newFee;
    }
}
