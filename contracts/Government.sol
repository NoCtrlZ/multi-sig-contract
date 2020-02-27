pragma solidity 0.6.0;

import './RingSig.sol';

contract Goverment {
    mapping(bytes32 => Proposal) proposals;
    bytes32[] proposalIndex;

    struct Proposal {
        string proposalTitle;
        bytes32 proposalHash;
        bool isApproved;
        RingSig ringsig;
        uint256 deadline;
        address proposer;
        uint256 threshold;
    }

    // check whether proposal hash is not exist and pulic key x y is same length
    modifier isValidProposal(_publicKeysX, _publicKeysY, proposalHash) {
        require(0 == uint256(proposals[proposalHash].proposalHash) && _publicKeysX.length == _publicKeysY.length);
        _;
    }

    // Initialize proposal with public key and deadline
    function propose(
        string memory proposalTitle,
        uint256[] memory _publicKeysX,
        uint256[] memory _publicKeysY,
        uint256 deadline
    )
    public
    isValidProposal
    {
        bytes32 proposalHash = keccak256(abi.encodePacked(proposalTitle, block.timestamp));
        uint256 threshold = _publicKeysX.length / 2;
        proposals[proposalHash] = Proposal (
            proposalTitle,
            proposalHash,
            false,
            new RingMultisig(_publicKeysX, _publicKeysY, threshold, proposalHash),
            deadline,
            msg.sender,
            threshold
        );
        proposalIndex.push(proposalHash);
    }

    // function agree(bytes32 _judgementHash, uint256[2] _tagPoint, uint256[] ctlist) public beforeDeadline(_judegementHash) {

    // }
}