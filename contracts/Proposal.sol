pragma solidity 0.6.0;

contract Goverment {
    mapping(bytes32 => Proposal) proposals;

    struct Proposal {
        string proposalTitle;
        bytes32 proposalHash;
        bool isApproved;
        uint256 deadline;
        address proposer;
        uint256 threshold;
    }

    function propose(
        string memory proposalTitle,
        uint256[] memory _publicKeysX,
        uint256[] memory _publicKeysY,
        uint256 deadline
    ) public {
        bytes32 proposalHash = keccak256(abi.encodePacked(proposalTitle, block.timestamp));
        uint256 threshold = _publicKeysX.length / 2;
        require(0 == uint256(proposals[proposalHash].proposalHash));
        require(_publicKeysX.length == _publicKeysY.length);
        proposals[proposalHash] = Proposal (
            proposalTitle,
            proposalHash,
            false,
            deadline,
            msg.sender,
            threshold
        );
    }
}
