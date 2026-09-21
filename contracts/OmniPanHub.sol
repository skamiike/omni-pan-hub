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
        bool requiresApproval; // true = "修正あり(クライアントの承認が必要)", false = "一発勝負(納品即時決済)"
        bool isCompleted;
        bool isApproved;
        bool isCancelled;
    }

    mapping(uint256 => Job) public jobs;

    event JobCreated(uint256 indexed jobId, address indexed client, address indexed creator, uint256 price, bool requiresApproval);
    event JobDelivered(uint256 indexed jobId, string tokenURI);
    event JobCompleted(uint256 indexed jobId, uint256 tokenId, string tokenURI);
    event JobCancelled(uint256 indexed jobId);

    constructor() ERC721("OmniPanHub NFT", "OPH") Ownable(msg.sender) {}

    // Client creates a job
    function createJob(address _creator, string memory _requirements, bool _requiresApproval) external payable {
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
            requiresApproval: _requiresApproval,
            isCompleted: false,
            isApproved: false,
            isCancelled: false
        });

        emit JobCreated(newJobId, msg.sender, _creator, msg.value, _requiresApproval);
    }

    // Creator delivers the job
    function deliverJob(uint256 _jobId, string memory _tokenURI) external {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.creator, "Only creator can deliver");
        require(!job.isCompleted && !job.isCancelled, "Job already closed");

        if (!job.requiresApproval) {
            // Skeb Style: 一発勝負の場合は即時完了＆決済
            _finalizeJob(_jobId, _tokenURI);
        } else {
            // 修正ありプラン: クライアントの承認待ち状態にする（イベント発行のみで仮納品）
            emit JobDelivered(_jobId, _tokenURI);
        }
    }

    // Client approves the delivered job (only needed if requiresApproval is true)
    function approveJob(uint256 _jobId, string memory _tokenURI) external {
        Job storage job = jobs[_jobId];
        require(msg.sender == job.client, "Only client can approve");
        require(job.requiresApproval, "Job does not require approval");
        require(!job.isCompleted && !job.isCancelled, "Job already closed");

        job.isApproved = true;
        _finalizeJob(_jobId, _tokenURI);
    }

    // Internal function to handle the actual minting and payment splitting
    function _finalizeJob(uint256 _jobId, string memory _tokenURI) internal {
        Job storage job = jobs[_jobId];
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
